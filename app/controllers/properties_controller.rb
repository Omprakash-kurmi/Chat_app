class PropertiesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false   # browsing is public

  def choose; end

  def index
    @listing_type = params[:listing_type]
    scope = Property.available.with_attached_photos.where(listing_type: @listing_type)

    if params[:city].present?
      scope = scope.where("city ILIKE ?", "%#{Property.sanitize_sql_like(params[:city])}%")
    end
    if Property.property_types.key?(params[:property_type])
      scope = scope.where(property_type: params[:property_type])
    end
    scope = scope.where("bedrooms >= ?", params[:bedrooms].to_i) if params[:bedrooms].present?
    scope = scope.where("price >= ?", params[:min_price].to_d) if params[:min_price].present?
    scope = scope.where("price <= ?", params[:max_price].to_d) if params[:max_price].present?

    @properties = scope.order(created_at: :desc)
  end

  def show
    @property = Property.find(params[:id])
  end
end
