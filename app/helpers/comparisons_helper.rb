module ComparisonsHelper
  CMP_MAX = 4

  def compare_ids
    Array(session[:compare_ids]).map(&:to_i).uniq.first(CMP_MAX)
  end

  def compare_properties
    @_compare_properties ||= begin
      ids   = compare_ids
      found = Property.where(id: ids).with_attached_gallery.index_by(&:id)
      ids.map { |i| found[i] }.compact
    end
  end

  # ---------- reading values (works with whatever columns exist) ----------
  def cmp_num(property, *names)
    names.each do |n|
      v = property.try(n)
      return v.to_f if v.is_a?(Numeric)
      return v.to_f if v.is_a?(String) && v.match?(/\A\d+(\.\d+)?\z/)
    end
    nil
  end

  def cmp_text(property, *names)
    names.each do |n|
      v = property.try(n)
      return v.to_s if v.present?
    end
    nil
  end

  def cmp_place(property)
    parts = [ cmp_text(property, :locality, :area_name, :address), cmp_text(property, :city) ]
    parts.compact_blank.join(", ").presence
  end

  def cmp_rent?(property)
    property.try(:listing_type).to_s == "rent"
  end

  def cmp_money(value, suffix = nil)
    return nil if value.blank?
    n =
      if value >= 10_000_000
        "#{number_with_precision(value / 10_000_000.0, precision: 2, strip_insignificant_zeros: true)} Cr"
      elsif value >= 100_000
        "#{number_with_precision(value / 100_000.0, precision: 2, strip_insignificant_zeros: true)} L"
      else
        number_with_delimiter(value.round)
      end
    "₹#{n}#{suffix}"
  end

  def cmp_price_label(property)
    cmp_money(cmp_num(property, :price, :rent, :amount), cmp_rent?(property) ? " / month" : nil)
  end

  def cmp_stars(rating)
    safe_join([
      content_tag(:span, "★★★★★", class: "cmpx-stars", style: "--rate: #{(rating.to_f / 5 * 100).round}%"),
      content_tag(:b, "#{rating.to_f.round(1)} / 5")
    ], " ")
  end

  def cmp_amenities(property)
    list = property.try(:amenities)
    list = list.split(",") if list.is_a?(String)
    Array(list).map { |a| a.to_s.strip }.reject(&:blank?)
  end

  # ---------- table rows ----------
  def cmp_rows(props)
    prices  = props.map { |p| cmp_num(p, :price, :rent, :amount) }
    areas   = props.map { |p| cmp_num(p, :area, :area_sqft, :carpet_area, :built_up_area, :size) }
    psf     = props.each_index.map { |i| prices[i] && areas[i]&.positive? ? (prices[i] / areas[i]).round : nil }
    ratings = props.map { |p| p.try(:reviews)&.any? ? p.try(:average_rating).to_f : nil }
    beds    = props.map { |p| cmp_num(p, :bedrooms, :bhk) }
    baths   = props.map { |p| cmp_num(p, :bathrooms) }

    rows = []
    rows << cmp_row("Rating", ratings, best: :max,
                    html: props.each_index.map { |i| ratings[i] ? safe_join([ cmp_stars(ratings[i]), content_tag(:small, "(#{props[i].reviews.size})") ], " ") : "—" })
    rows << cmp_row("Price", prices, best: :min,
                    html: props.each_index.map { |i| cmp_money(prices[i], cmp_rent?(props[i]) ? " / month" : nil) || "—" })
    rows << cmp_row("Location", props.map { |p| cmp_place(p) })
    rows << cmp_row("Bedrooms", beds, html: beds.map { |v| v ? "#{v.to_i} BHK" : "—" })
    rows << cmp_row("Bathrooms", baths, html: baths.map { |v| v ? v.to_i.to_s : "—" })
    rows << cmp_row("Property type", props.map { |p| cmp_text(p, :property_type)&.humanize })
    rows << cmp_row("Furnishing", props.map { |p| p.try(:furnishing_label).presence || cmp_text(p, :furnishing)&.humanize })
    rows << cmp_row("Area", areas, best: :max,
                    html: areas.map { |v| v ? "#{number_with_delimiter(v.round)} sq ft" : "—" })
    rows << cmp_row("Price / sq ft", psf, best: :min,
                    html: psf.map { |v| v ? "₹#{number_with_delimiter(v)} / sq ft" : "—" })
    rows << cmp_row("Parking", props.map { |p| cmp_parking(p) })
    rows << cmp_row("Available", props.map { |p| cmp_available(p) })
    rows << cmp_row("Listing type", props.map { |p| p.try(:listing_type).to_s.presence&.humanize })
    rows << cmp_row("Availability", props.map { |p| p.respond_to?(:available) ? (p.available ? "Available" : "Not available") : nil })

    rows << cmp_row("Land type", props.map { |p| p.land? ? p.land_kind_label : nil })
    rows << cmp_row("Plot dimensions", props.map { |p| p.plot_dimensions })
    rows << cmp_row("Facing", props.map { |p| p.facing.presence })
    rows << cmp_row("Road width", props.map { |p| p.road_width_ft ? "#{p.road_width_ft} ft" : nil })
    rows << cmp_row("Boundary wall", props.map { |p| p.land? ? (p.boundary_wall ? "Yes" : "No") : nil })

    rows.reject! { |r| r[:raw].all?(&:blank?) }

    amenity_names = defined?(Property::AMENITIES) ? Property::AMENITIES : props.flat_map { |p| cmp_amenities(p) }.uniq
    if amenity_names.any? && props.any? { |p| cmp_amenities(p).any? }
      rows << { section: "Amenities" }
      amenity_names.each do |a|
        have = props.map { |p| cmp_amenities(p).include?(a) }
        rows << cmp_row(a, have.map { |h| h ? "Yes" : "No" },
                        html: have.map { |h| h ? content_tag(:span, "✓", class: "cmpx-yes") : content_tag(:span, "✕", class: "cmpx-no") })
      end
    end
    rows
  end

  def cmp_best_index(row)
    return nil unless row[:best]
    nums = row[:raw].each_with_index.select { |v, _| v.is_a?(Numeric) }
    return nil if nums.size < 2 || nums.map(&:first).uniq.size == 1
    (row[:best] == :min ? nums.min_by(&:first) : nums.max_by(&:first)).last
  end

  def cmp_same?(row)
    row[:raw].map(&:to_s).uniq.size == 1
  end

  private

  def cmp_row(label, raw, html: nil, best: nil)
    { label: label, raw: raw, best: best, html: html || raw.map { |v| v.to_s.presence || "—" } }
  end

  def cmp_bool(property, name)
    v = property.try(name)
    return nil if v.nil? && !property.respond_to?(name)
    return "Yes" if v == true
    return "No" if v == false || v.nil?
    v.to_s
  end

  def cmp_date(property)
    d = property.try(:available_from) || property.try(:available_by) || property.try(:available_on)
    d.respond_to?(:strftime) ? d.strftime("%d %b %Y") : nil
  end

  def cmp_parking(property)
    return cmp_bool(property, :parking) unless property.respond_to?(:parking_spaces)
    n = property.parking_spaces.to_i
    n.positive? ? "#{n} #{'space'.pluralize(n)}" : "No"
  end

  def cmp_available(property)
    return "Available now" if property.try(:available_now?)
    d = property.try(:available_from)
    d.respond_to?(:strftime) ? "From #{d.strftime('%d %b %Y')}" : nil
  end
end
