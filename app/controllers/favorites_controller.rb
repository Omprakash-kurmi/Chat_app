class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: %i[create destroy]

  # My Favorites
  def index
    @favorites = current_user.favorites
                             .joins(:property).merge(Property.published)
                             .includes(property: { photos_attachments: :blob })
                             .order(created_at: :desc)
                             .page(params[:page]).per(12)
  end

  def create
    favorite = current_user.favorites.find_or_initialize_by(property: @property)
    if favorite.save
      respond(notice: "Saved to your favorites")
    else
      respond(alert: favorite.errors.full_messages.to_sentence)
    end
  end

  def destroy
    current_user.favorites.where(property: @property).destroy_all
    respond(notice: "Removed from your favorites")
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
    own = @property.user_id == current_user.id
    raise ActiveRecord::RecordNotFound unless @property.published? || own
  end

  # Turbo swaps just the heart; plain HTML falls back to a redirect.
  def respond(flash_message)
    @remove_card = params[:remove_card].present?
    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back fallback_location: property_path(@property), status: :see_other, **flash_message
      end
    end
  end
end
