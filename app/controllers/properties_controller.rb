class PropertiesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false   # browsing is public

  def choose; end

  # def index
  #   @listing_type = params[:listing_type]
  #   @properties = Property.available.with_attached_photos
  #                         .where(listing_type: @listing_type)
  #                         .matching(params)
  #                         .sorted(params[:sort])
  #                         .page(params[:page]).per(12)
  # end
  def index
    @listing_type = params[:listing_type]

    @properties = Property.with_attached_photos
                          .where(listing_type: @listing_type)

    if current_user.vendor?
      @properties = @properties.where(user: current_user)
    else
      @properties = @properties.available
    end

    @properties = @properties
                    .matching(params)
                    .sorted(params[:sort])
                    .page(params[:page])
                    .per(12)
  end

  # def show
  #   @property = Property.find(params[:id])
  # end
  def show
    @property = Property.find(params[:id])
    # unverified / closed listings are visible only to their owner
    own_listing = user_signed_in? && @property.user_id == current_user.id
    # raise ActiveRecord::RecordNotFound unless @property.published? || own_listing
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

  def property_params
    params.require(:property).permit(
      :title, :listing_type, :property_type, :price, :security_deposit, :bedrooms, :bathrooms,
      :area_sqft, :furnishing, :parking_spaces, :floor_number, :total_floors, :age_years,
      :address, :locality, :city, :pincode, :latitude, :longitude, :description,
      :poster_type, :contact_name, :contact_phone, :visiting_hours, :available_from, :available,
      amenities: [], photos: [], videos: []
    )
  end
end
