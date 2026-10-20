require "net/http"
require "json"

class AiPropertyAssistant
  MODEL = ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")
  KINDS = %w[rent buy land].freeze

  PG_WORDS = /\b(pg|p\.g\.?|hostel|hostels|hostle|hostile|paying\s*guest|co-?living)\b/i

  FACILITY_WORDS = {
    "wifi"           => /wi-?fi|internet/i,
    "meals"          => /\bmeals?\b|\bfood\b|\bmess\b|tiffin/i,
    "laundry"        => /laundry|washing/i,
    "ac"             => /\bac\b|air.?condition/i,
    "hot_water"      => /hot\s*water|geyser/i,
    "power_backup"   => /power\s*backup|inverter|generator/i,
    "cctv"           => /cctv/i,
    "housekeeping"   => /housekeeping/i,
    "parking"        => /parking/i,
    "gym"            => /\bgym\b/i,
    "study_room"     => /study\s*room/i,
    "tv"             => /\btv\b|television/i,
    "fridge"         => /fridge|refrigerator/i,
    "water_purifier" => /\bro\b|purifier/i,
    "lift"           => /\blift\b|elevator/i,
    "bed_linen"      => /bed\s*(&|and)?\s*linen/i
  }.freeze

  def initialize(message, history: [])
    @message = message
    @history = history
  end

  def call
    filters, reply = ENV["ANTHROPIC_API_KEY"].present? ? ask_claude : [ rule_filters, nil ]
    filters = with_pg(filters)
    props = search(filters)
    { reply: reply.presence || fallback_reply(filters, props), properties: props }
  rescue StandardError => e
    Rails.logger.warn("[AiPropertyAssistant] #{e.class}: #{e.message}")
    filters = with_pg(rule_filters)
    props   = search(filters)
    { reply: fallback_reply(filters, props), properties: props }
  end

  private

  # ---------- Claude ----------
  def ask_claude
    uri  = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 20

    req = Net::HTTP::Post.new(uri)
    req["content-type"]      = "application/json"
    req["x-api-key"]         = ENV["ANTHROPIC_API_KEY"]
    req["anthropic-version"] = "2023-06-01"
    req.body = {
      model: MODEL,
      max_tokens: 400,
      system: system_prompt,
      messages: (@history + [ { role: "user", text: @message } ]).map { |m| { role: m[:role], content: m[:text] } }
    }.to_json

    res = http.request(req)
    raise "Claude API #{res.code}: #{res.body.to_s.first(200)}" unless res.is_a?(Net::HTTPSuccess)

    text = JSON.parse(res.body).dig("content", 0, "text").to_s
    json = JSON.parse(text[/\{.*\}/m] || "{}")
    [ json["filters"].is_a?(Hash) ? json["filters"] : {}, json["reply"] ]
  end

  def system_prompt
    cities = column?("city") ? Property.publicly_visible.distinct.pluck(:city).compact.first(60) : []
    <<~P
      You are the friendly property assistant of an Indian real-estate app (rent, buy, land/plots, and PG / hostel rooms).
      Reply with ONLY a JSON object, no other text:
      {"reply": "<1-2 short friendly sentences>",
       "filters": {"listing_type": "rent|buy|land|null", "city": null, "locality": null,
                   "min_price": null, "max_price": null, "bhk": null, "land_type": null,
                   "pg": null, "facilities": []}}
      Rules: prices are integers in rupees (1 lakh = 100000, 1 crore = 10000000). bhk is an integer.
      land_type is one of residential, commercial, agricultural, industrial or null.
      Set "pg" to true when the user wants a PG, hostel, paying guest or co-living room.
      "facilities" may contain: #{Property::PG_FACILITIES.keys.join(', ')}.
      Known cities: #{cities.join(', ')}.
      If the user is only chatting or greeting, set all filters to null and answer helpfully.
      Never invent properties; the app shows real results under your reply.
    P
  end

  # ---------- PG / hostel (works with or without Claude) ----------
  def with_pg(filters)
    f = filters.to_h.transform_keys(&:to_s)
    if f["pg"].to_s == "true"
      s = pg_scope(s)

      wanted = Array(f["facilities"]) & pg_keys
      if wanted.any? && column?("facilities")
        s = s.where("properties.facilities @> ARRAY[?]::varchar[]", wanted)
      end
    end
    f
  end

  # ---------- Fallback (no API key / API error) ----------
  def rule_filters
    t = @message.downcase
    f = {}
    f["listing_type"] =
      if t =~ /\b(land|plot|plots)\b/ then "land"
      elsif t =~ /\b(rent|rental|lease)\b/ then "rent"
      elsif t =~ /\b(buy|sale|purchase|own)\b/ then "buy"
      end
    f["bhk"] = t[/(\d)\s*bhk/, 1]&.to_i
    if (m = t.match(/(?:under|below|upto|up to|less than|within|max)\s*(?:rs\.?|₹)?\s*([\d.,]+)\s*(cr|crore|l|lac|lakh|lakhs|k|thousand)?/))
      f["max_price"] = to_rupees(m[1], m[2])
    end
    if (m = t.match(/(?:above|over|more than|min|from)\s*(?:rs\.?|₹)?\s*([\d.,]+)\s*(cr|crore|l|lac|lakh|lakhs|k|thousand)?/))
      f["min_price"] = to_rupees(m[1], m[2])
    end
    if column?("city")
      f["city"] = Property.publicly_visible.distinct.pluck(:city).compact.find { |c| t.include?(c.downcase) }
    end
    f.compact
  end

  def to_rupees(num, unit)
    n = num.to_s.delete(",").to_f
    mult = case unit.to_s
    when "cr", "crore" then 10_000_000
    when "l", "lac", "lakh", "lakhs" then 100_000
    when "k", "thousand" then 1_000
    else 1
    end
    (n * mult).to_i
  end

  # ---------- Search ----------
  def search(f)
    f = f.to_h.transform_keys(&:to_s).compact_blank
    return [] if f.empty?

    s = Property.publicly_visible
    s = s.available if Property.respond_to?(:available)

    s = s.where(listing_type: f["listing_type"]) if KINDS.include?(f["listing_type"].to_s)
    s = s.where("LOWER(properties.city) = ?", f["city"].to_s.downcase)        if f["city"].present? && column?("city")
    s = s.where("properties.locality ILIKE ?", "%#{f['locality']}%")          if f["locality"].present? && column?("locality")
    s = s.where("properties.price >= ?", f["min_price"].to_i)                 if f["min_price"].to_i > 0 && column?("price")
    s = s.where("properties.price <= ?", f["max_price"].to_i)                 if f["max_price"].to_i > 0 && column?("price")
    bhk_col = %w[bhk bedrooms].find { |c| column?(c) }
    s = s.where(bhk_col => f["bhk"].to_i)                                     if f["bhk"].to_i > 0 && bhk_col
    s = s.where(land_type: f["land_type"])                                    if f["land_type"].present? && Property.land_types.key?(f["land_type"].to_s)

    if f["pg"].to_s == "true"
      cond = [ "properties.property_type ILIKE ANY (ARRAY['%pg%','%hostel%','%paying%'])" ]
      cond << "cardinality(properties.facilities) > 0" if column?("facilities")
      s = s.where(cond.join(" OR "))

      wanted = Array(f["facilities"]) & Property::PG_FACILITIES.keys
      if wanted.any? && column?("facilities")
        s = s.where("properties.facilities @> ARRAY[?]::varchar[]", wanted)
      end
    end

    s.order(created_at: :desc).limit(5).to_a
  end

  def fallback_reply(filters, props)
    pg = filters.to_h.transform_keys(&:to_s)["pg"].to_s == "true"
    if filters.blank?
      "Hi! Tell me what you are looking for, for example “2BHK for rent in Indore under 30k”, “PG with wifi and meals” or “plots under 50 lakh”."
    elsif props.any?
      "I found #{props.size} #{(pg ? 'PG / hostel' : 'property').pluralize(props.size)} that match. Take a look:"
    elsif pg
      "I couldn't find a PG or hostel for that yet. Try another city, a higher budget or fewer facilities."
    else
      "I couldn't find an exact match. Try a higher budget or a nearby city."
    end
  end

  def column?(name)
    Property.column_names.include?(name)
  end

  def pg_keys
    defined?(Property::PG_FACILITIES) ? Property::PG_FACILITIES.keys : FACILITY_WORDS.keys
  end

  # Listings that are a PG / hostel type, or that have facilities ticked
  def pg_scope(base)
    by_type =
      if column?("property_type") && Property.respond_to?(:property_types)
        names = Property.property_types.keys.grep(/pg|hostel|paying/i)
        names.any? ? base.where(property_type: names) : base.none
      elsif column?("property_type")
        base.where("CAST(properties.property_type AS TEXT) ILIKE ANY (ARRAY['%pg%','%hostel%','%paying%'])")
      else
        base.none
      end

    return by_type unless column?("facilities")

    by_type.or(base.where("cardinality(properties.facilities) > 0"))
  end
end