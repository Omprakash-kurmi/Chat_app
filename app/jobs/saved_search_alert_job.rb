# Runs when a listing becomes visible. Finds saved searches it matches and notifies their owners.
# (With the default :async adapter this runs in-process; use Sidekiq/GoodJob etc. in production.)
class SavedSearchAlertJob < ApplicationJob
  queue_as :default

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property && property.published? && property.available?

    paths = Rails.application.routes.url_helpers
    SavedSearch.alerting.where(listing_type: property.listing_type)
               .where.not(user_id: property.user_id).includes(:user).find_each do |search|
      next unless search.matches?(property)

      note = Notification.new(
        user: search.user, kind: "saved_search_match",
        title: "New match for “#{search.name}”",
        body: "#{property.title} — #{[ property.locality, property.city ].compact_blank.join(', ')}",
        path: paths.property_path(property),
        dedupe_key: "saved_search:#{search.id}:property:#{property.id}"
      )
      begin
        note.save!
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        next   # already alerted for this listing
      end

      search.update_columns(last_notified_at: Time.current)
      SavedSearchMailer.new_match(search, property).deliver_later
    end
  end
end
