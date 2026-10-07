class SavedSearchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search, only: %i[update destroy]

  def index
    @searches = current_user.saved_searches.order(created_at: :desc)
  end

  def create
    listing_type = params[:listing_type].to_s
    filters      = SavedSearch.clean_filters(params)

    existing = current_user.saved_searches.detect { |s| s.listing_type == listing_type && s.filters == filters }
    if existing
      return redirect_back fallback_location: saved_searches_path, status: :see_other,
                           notice: "You already saved this search."
    end

    search = current_user.saved_searches.new(
      listing_type: listing_type, filters: filters,
      name: SavedSearch.default_name(listing_type, filters)
    )
    if search.save
      redirect_to saved_searches_path, status: :see_other,
                  notice: "Search saved. We'll notify you when a matching home is listed."
    else
      redirect_back fallback_location: saved_searches_path, status: :see_other,
                    alert: search.errors.full_messages.to_sentence
    end
  end

  # rename or switch alerts on/off
  def update
    if @search.update(params.require(:saved_search).permit(:name, :notify))
      redirect_to saved_searches_path, status: :see_other,
                  notice: (@search.notify? ? "Alerts are on." : "Alerts paused.")
    else
      redirect_to saved_searches_path, status: :see_other, alert: @search.errors.full_messages.to_sentence
    end
  end

  def destroy
    @search.destroy
    redirect_to saved_searches_path, status: :see_other, notice: "Saved search deleted."
  end

  private

  def set_search
    @search = current_user.saved_searches.find(params[:id])
  end
end
