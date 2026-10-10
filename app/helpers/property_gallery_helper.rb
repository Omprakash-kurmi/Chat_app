module PropertyGalleryHelper
  # All photos of a property: the new gallery plus any older image attachments.
    PG_USE_VARIANTS = false

  def property_slides(property)
    list = []
    %i[gallery images photos image photo].each do |name|
      next unless property.respond_to?(name)
      att = property.public_send(name)
      next unless att.respond_to?(:attached?) && att.attached?
      list.concat(att.respond_to?(:attachments) ? att.attachments.to_a : [att.attachment])
    end
    list.compact.uniq { |a| a.blob_id }
  end

  def pg_title(property)
    property.try(:title).presence || property.try(:name).presence || property.try(:listing_type).presence || "Property"
  end

  def pg_place(property)
    property.try(:city).presence || property.try(:location).presence || property.try(:address).presence
  end

  def pg_price(property)
    value = property.try(:price) || property.try(:rent)
    value.present? ? number_to_currency(value, unit: "₹", precision: 0) : nil
  end

  def pg_src(attachment, size = nil)
    PG_USE_VARIANTS && size && attachment.variable? ? attachment.variant(resize_to_limit: size) : attachment
  end

  def vendor_user?
    return false unless user_signed_in?
    u = current_user
    return u.vendor? if u.respond_to?(:vendor?)
    return u.vendor if u.respond_to?(:vendor) && [true, false].include?(u.vendor)
    %i[account_type user_type kind role].any? { |f| u.respond_to?(f) && u.public_send(f).to_s == "vendor" }
  end

  # The photo slider is shown to customers and visitors, not to vendors.
  def show_property_slider?
    !vendor_user?
  end

end