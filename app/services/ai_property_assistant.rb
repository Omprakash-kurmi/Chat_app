require "net/http"
require "json"

class AiPropertyAssistant
  MODEL = ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")
  KINDS = %w[rent buy land].freeze

  def initialize(message, history: [])
    @message = message
    @history = history
  end

  def call
    filters, reply = ENV["ANTHROPIC_API_KEY"].present? ? ask_claude : [ rule_filters, nil ]
    props = search(filters)
    { reply: reply.presence || fallback_reply(filters, props), properties: props }
  rescue StandardError => e
    Rails.logger.warn("[AiPropertyAssistant] #{e.class}: #{e.message}")
    filters = rule_filters
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
      You are the friendly property assistant of an Indian real-estate app (rent, buy and land/plots).
      Reply with ONLY a JSON object, no other text:
      {"reply": "<1-2 short friendly sentences>",
       "filters": {"listing_type": "rent|buy|land|null", "city": null, "locality": null,
                   "min_price": null, "max_price": null, "bhk": null, "land_type": null}}
      Rules: prices are integers in rupees (1 lakh = 100000, 1 crore = 10000000). bhk is an integer.
      land_type is one of residential, commercial, agricultural, industrial or null.
      Known cities: #{cities.join(', ')}.
      If the user is only chatting or greeting, set all filters to null and answer helpfully.
      Never invent properties; the app shows real results under your reply.
    P
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

    s.order(created_at: :desc).limit(5).to_a
  end

  def fallback_reply(filters, props)
    if filters.blank?
      "Hi! Tell me what you are looking for, for example “2BHK for rent in Indore under 30k” or “plots under 50 lakh”."
    elsif props.any?
      "I found #{props.size} #{'property'.pluralize(props.size)} that match. Take a look:"
    else
      "I couldn't find an exact match. Try a higher budget or a nearby city."
    end
  end

  def column?(name)
    Property.column_names.include?(name)
  end
end