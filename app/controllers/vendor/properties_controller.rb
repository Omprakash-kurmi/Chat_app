module Vendor
  class PropertiesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_vendor!
    before_action :set_property, only: %i[edit update destroy]

    def index
      @properties = current_user.properties.with_attached_photos.order(created_at: :desc)
    end

    def new
      @property = current_user.properties.new
    end

    def create
      @property = current_user.properties.new(property_params)
      if @property.save
        redirect_to vendor_properties_path, notice: "Listing published."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @property.photos.attachments.where(id: params[:remove_photo_ids]).each(&:purge_later) if params[:remove_photo_ids].present?
      if @property.update(property_params)
        redirect_to vendor_properties_path, notice: "Listing updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to vendor_properties_path, notice: "Listing deleted."
    end

    private

    def require_vendor!
      redirect_to root_path, alert: "Only vendor accounts can manage listings." unless current_user.vendor?
    end

    # scoped to the signed-in vendor, so nobody can edit someone else's listing
    def set_property
      @property = current_user.properties.find(params[:id])
    end

    def property_params
      params.require(:property).permit(:title, :listing_type, :property_type, :price, :bedrooms,
        :bathrooms, :area_sqft, :address, :city, :description, :contact_phone,
        :visiting_hours, :available, photos: [])
    end
  end
end
