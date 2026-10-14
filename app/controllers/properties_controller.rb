class PropertiesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false   # browsing is public

  def choose; end

  def index
    @listing_type = params[:listing_type]

    @properties = Property.with_attached_photos
                          .where(listing_type: @listing_type)

    if current_user&.vendor?
      @properties = @properties.where(user: current_user)      # vendors still see all their own
    else
      @properties = @properties.publicly_visible.available     # customers: approved only
    end

    @properties = @properties
                    .matching(params)
                    .sorted(params[:sort])
                    .page(params[:page])
                    .per(12)
  end

  def show
    @property = Property.find(params[:id])

    own_listing = user_signed_in? && @property.user_id == current_user.id
    admin_view  = respond_to?(:admin_user_signed_in?, true) && admin_user_signed_in?

    unless @property.status == "published" || own_listing || admin_view
      raise ActiveRecord::RecordNotFound      # customers get a 404 for unapproved listings
    end
    @nearby_properties  = @property.nearby_properties(3)
    @similar_properties = @property.similar_properties(3, exclude_ids: @nearby_properties.map(&:id))
  end

  def update
    if params[:remove_photo_ids].present?
      @property.photos.attachments.where(id: params[:remove_photo_ids]).each(&:purge_later)
    end
    if params[:remove_video_ids].present?
      @property.videos.attachments.where(id: params[:remove_video_ids]).each(&:purge_later)
    end

    if @property.update(property_params)
      redirect_to vendor_properties_path, notice: "Listing updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @property = current_user.properties.new(property_params)

    if @property.save
      redirect_to vendor_properties_path, notice: "Property published successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  
  def property_params
    params.require(:property).permit(
      :title, :listing_type, :property_type, :price, :security_deposit,
      :available_from, :bedrooms, :bathrooms, :area_sqft, :parking_spaces,
      :furnishing, :floor_number, :total_floors, :age_years,
      :address, :locality, :city, :pincode, :latitude, :longitude,
      :poster_type, :contact_name, :contact_phone, :visiting_hours,
      :description, :available,
      :land_type, :land_area, :area_unit, :plot_length, :plot_width,
      :facing, :road_width_ft, :boundary_wall, :corner_plot,
      :ownership_type, :approval_authority,
      amenities: [], photos: [], videos: []
    )
  end
end
