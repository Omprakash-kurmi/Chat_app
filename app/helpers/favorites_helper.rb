module FavoritesHelper
  # one query per request, however many cards are on the page
  def favorite_ids
    @favorite_ids ||= user_signed_in? ? current_user.favorites.pluck(:property_id).to_set : Set.new
  end

  def favorited?(property)
    favorite_ids.include?(property.id)
  end

  def unread_notifications_count
    return 0 unless user_signed_in?
    @unread_notifications_count ||= current_user.notifications.unread.count
  end

  # hidden inputs that carry the currently applied search into the "Save this search" form
  def search_hidden_fields(listing_type)
    fields = [ hidden_field_tag(:listing_type, listing_type, id: nil) ]
    SavedSearch::SCALAR_KEYS.each do |key|
      fields << hidden_field_tag(key, params[key], id: nil) if params[key].present?
    end
    SavedSearch::ARRAY_KEYS.each do |key|
      Array(params[key]).reject(&:blank?).each { |v| fields << hidden_field_tag("#{key}[]", v, id: nil) }
    end
    safe_join(fields)
  end

  def search_applied?
    (SavedSearch::SCALAR_KEYS + SavedSearch::ARRAY_KEYS).any? { |k| params[k].present? }
  end
end
