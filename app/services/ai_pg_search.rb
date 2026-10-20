class AiPgSearch
  PG_WORDS = /\b(pg|p\.g\.?|hostel|hostle|hostile|paying\s*guest|co-?living|girls\s*pg|boys\s*pg)\b/i

  FACILITY_WORDS = {
    "wifi"           => /wi-?fi|internet/i,
    "meals"          => /meal|food|mess|tiffin/i,
    "laundry"        => /laundry|washing/i,
    "ac"             => /\bac\b|air.?condition/i,
    "hot_water"      => /hot\s*water|geyser/i,
    "power_backup"   => /power\s*backup|inverter|generator/i,
    "cctv"           => /cctv|security/i,
    "housekeeping"   => /housekeeping|cleaning/i,
    "parking"        => /parking/i,
    "gym"            => /\bgym\b/i,
    "study_room"     => /study/i,
    "tv"             => /\btv\b|television/i,
    "fridge"         => /fridge|refrigerator/i,
    "water_purifier" => /\bro\b|purifier/i,
    "lift"           => /\blift\b|elevator/i,
    "bed_linen"      => /bed|linen/i
  }.freeze

  def self.match?(text)
    text.to_s.match?(PG_WORDS)
  end

  def self.call(text)
    return nil unless match?(text)

    scope = Property.publicly_visible
    scope = scope.available if Property.respond_to?(:available)
    scope = scope.where(
      "properties.property_type ILIKE ANY (ARRAY['%pg%','%hostel%','%paying%']) " \
      "OR cardinality(properties.facilities) > 0"
    )

    wanted = FACILITY_WORDS.select { |_k, rx| text.match?(rx) }.keys
    scope  = scope.where("properties.facilities @> ARRAY[?]::varchar[]", wanted) if wanted.any?

    if (city = Property.distinct.pluck(:city).compact.find { |c| text.match?(/\b#{Regexp.escape(c)}\b/i) })
      scope = scope.where("LOWER(properties.city) = ?", city.downcase)
    end

    if (m = text.match(/under\s*(\d+)\s*(k|thousand|lakh|l)?/i))
      n = m[1].to_i
      n *= 1_000 if m[2]&.match?(/k|thousand/i)
      n *= 100_000 if m[2]&.match?(/lakh|l/i)
      scope = scope.where("properties.price <= ?", n)
    end

    list = scope.order(created_at: :desc).limit(5)
    reply =
      if list.any?
        "I found #{list.size} PG / hostel #{list.size == 1 ? 'listing' : 'listings'} for you:"
      else
        "I couldn't find a PG or hostel for that yet. Try a different city or fewer facilities."
      end

    { reply: reply, properties: list }
  end
end
