module Vendor
  class PropertiesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_vendor!
    before_action :set_property, only: %i[edit update destroy reopen]

    def index
      @properties = current_user.properties.with_attached_photos.order(created_at: :desc)
      mine = Inquiry.where(property_id: current_user.properties.select(:id))
      @total_counts = mine.group(:property_id).count
      @pending_counts = mine.pending.group(:property_id).count
    end

    def new
      @property = current_user.properties.new(available: true)
    end

    def create
      @property = current_user.properties.new(property_params)   # starts as "pending"
      if @property.save
        redirect_to vendor_properties_path,
                    notice: "Listing submitted. It will go live once an admin verifies it."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @property.photos.attachments.where(id: params[:remove_photo_ids]).each(&:purge_later) if params[:remove_photo_ids].present?
      @property.videos.attachments.where(id: params[:remove_video_ids]).each(&:purge_later) if params[:remove_video_ids].present?

      @property.assign_attributes(property_params)
      resubmitting = @property.rejected?
      if resubmitting
        @property.status = :pending
        @property.rejection_reason = nil
      end

      if @property.save
        redirect_to vendor_properties_path,
                    notice: resubmitting ? "Updated and sent for verification again." : "Listing updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to vendor_properties_path, notice: "Listing deleted.", status: :see_other
    end

    # put a closed (deal done) listing back on the market
    def reopen
      if @property.reopen!
        redirect_to vendor_properties_path, notice: "Listing is live again.", status: :see_other
      else
        redirect_to vendor_properties_path, alert: "Only closed listings can be reopened.", status: :see_other
      end
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
      params.require(:property).permit(
        :title, :listing_type, :property_type, :price, :security_deposit, :bedrooms, :bathrooms,
        :area_sqft, :furnishing, :parking_spaces, :floor_number, :total_floors, :age_years,
        :address, :locality, :city, :pincode, :latitude, :longitude, :description,
        :poster_type, :contact_name, :contact_phone, :visiting_hours, :available_from, :available,
        amenities: [], photos: [], videos: []
      )
    end
  end
end
