class ComparisonsController < ApplicationController
  MAX = 4

  before_action :authenticate_user!
  before_action :customers_only

  def show
    ids   = compare_ids
    found = Property.where(id: ids, status: "published")
                .includes(:reviews).with_attached_gallery.with_attached_photos.index_by(&:id)
    @properties = ids.map { |i| found[i] }.compact
    session[:compare_ids] = @properties.map(&:id) # drop anything no longer published

    # Lets the view switch rows/labels: all land, no land, or a mix
    @all_land = @properties.any? && @properties.all?(&:land?)
    @any_land = @properties.any?(&:land?)
    @mixed    = @any_land && !@all_land
  end

  def add
    property = Property.where(status: "published").find(params[:property_id])
    ids = compare_ids

    flash_opts =
      if ids.include?(property.id)
        { notice: "Already in your comparison." }
      elsif ids.size >= MAX
        { alert: "You can compare up to #{MAX} properties. Remove one first." }
      else
        session[:compare_ids] = ids + [ property.id ]
        { notice: "#{compare_label(property)} added to compare." }
      end

    redirect_back fallback_location: compare_path, status: :see_other, **flash_opts
  end

  def remove
    session[:compare_ids] = compare_ids - [ params[:property_id].to_i ]
    redirect_back fallback_location: compare_path, status: :see_other
  end

  def clear
    session[:compare_ids] = []
    redirect_to compare_path, status: :see_other, notice: "Comparison cleared."
  end

  private

  def compare_ids
    Array(session[:compare_ids]).map(&:to_i).uniq.first(MAX)
  end

  # pg_title may read oddly for plots, so use a simple label for land
  def compare_label(property)
    if property.land?
      [ property.try(:title), property.try(:city) ].compact_blank.join(", ").presence || "Plot"
    else
      helpers.pg_title(property)
    end
  end

  def customers_only
    redirect_to search_home_path, alert: "Comparison is available for customers." if helpers.vendor_user?
  end
end