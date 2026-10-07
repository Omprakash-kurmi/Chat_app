class Property < ApplicationRecord
  include PropertyWorkflow
  AMENITIES = [
    "Lift", "Power backup", "24x7 security", "CCTV", "Gym", "Swimming pool", "Clubhouse", "Garden",
    "Children's play area", "24x7 water supply", "Gas pipeline", "Intercom", "Visitor parking",
    "Rainwater harvesting", "Pet friendly", "Wi-Fi ready"
  ].freeze

  belongs_to :user
  has_many_attached :photos
  has_many_attached :videos
  has_many :inquiries, dependent: :destroy
  has_many :inquiry_messages, dependent: :destroy
  has_many :proposed_visits, class_name: "Visit", foreign_key: :proposed_by_id, dependent: :destroy

  enum :listing_type,  { rent: 0, buy: 1 }
  enum :property_type, { apartment: 0, house: 1, villa: 2, plot: 3, studio: 4, penthouse: 5, commercial: 6 }
  enum :furnishing,    { unfurnished: 0, semi_furnished: 1, furnished: 2 }
  enum :poster_type,   { owner: 0, agent: 1 }

  before_validation :tidy

  validates :title, :address, :city, :contact_phone, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :pincode, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, allow_blank: true
  validates :security_deposit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :photos_valid, :videos_valid

  scope :available, -> { where(available: true) }

  # ---------- search ----------
  def self.matching(params)
    f = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    scope = all

    if (q = f["q"].to_s.strip).present?
      term = sanitize_sql_like(q)
      scope = scope.where(
        "city ILIKE :any OR locality ILIKE :any OR address ILIKE :any OR pincode LIKE :pin",
        any: "%#{term}%", pin: "#{term}%"
      )
    end

    scope = scope.where("price >= ?", f["min_price"].to_d) if f["min_price"].present?
    scope = scope.where("price <= ?", f["max_price"].to_d) if f["max_price"].present?

    types = Array(f["property_types"]) & property_types.keys
    scope = scope.where(property_type: types) if types.any?

    scope = scope.where("bedrooms >= ?", f["bedrooms"].to_i) if f["bedrooms"].present?

    wanted_furnishing = Array(f["furnishings"]) & furnishings.keys
    scope = scope.where(furnishing: wanted_furnishing) if wanted_furnishing.any?

    scope = scope.where("area_sqft >= ?", f["min_area"].to_i) if f["min_area"].present?
    scope = scope.where("area_sqft <= ?", f["max_area"].to_i) if f["max_area"].present?
    scope = scope.where("parking_spaces > 0") if f["parking"].to_s == "1"

    wanted_amenities = Array(f["amenities"]) & AMENITIES
    scope = scope.where("amenities @> ARRAY[?]::varchar[]", wanted_amenities) if wanted_amenities.any?

    if f["available_by"].present?
      date = (Date.parse(f["available_by"].to_s) rescue nil)
      scope = scope.where("available_from IS NULL OR available_from <= ?", date) if date
    end

    scope
  end

  def self.sorted(key)
    case key
    when "price_asc"  then order(:price)
    when "price_desc" then order(price: :desc)
    when "area_desc"  then order(Arel.sql("area_sqft DESC NULLS LAST"))
    else order(created_at: :desc)
    end
  end

  # ---------- display helpers ----------
  def furnishing_label
    furnishing.humanize.sub("Semi furnished", "Semi-furnished")
  end

  def available_now?
    available? && (available_from.nil? || available_from <= Date.current)
  end

  def floor_label
    return if floor_number.nil?
    base = floor_number.zero? ? "Ground" : floor_number.ordinalize
    total_floors ? "#{base} of #{total_floors}" : base
  end

  def maps_query
    return "#{latitude},#{longitude}" if latitude && longitude
    [ address, locality, city, pincode ].compact_blank.join(", ")
  end

  private

  def tidy
    self.amenities = Array(amenities).reject(&:blank?) & AMENITIES
    self.pincode = pincode.to_s.strip.presence
    self.security_deposit = nil if buy?
  end

  def photos_valid
    errors.add(:photos, "– add at least one photo") if new_record? && !photos.attached?
    errors.add(:photos, "– maximum is 8") if photos.size > 8
    photos.each do |p|
      errors.add(:photos, "must be images") unless p.content_type.to_s.start_with?("image/")
      errors.add(:photos, "must be under 5 MB") if p.byte_size > 5.megabytes
    end
  end

  def videos_valid
    errors.add(:videos, "– maximum is 2") if videos.size > 2
    videos.each do |v|
      errors.add(:videos, "must be video files") unless v.content_type.to_s.start_with?("video/")
      errors.add(:videos, "must be under 50 MB") if v.byte_size > 50.megabytes
    end
  end
  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "title",
      "description",
      "address",
      "locality",
      "city",
      "pincode",
      "contact_name",
      "contact_phone",
      "listing_type",
      "property_type",
      "furnishing",
      "poster_type",
      "price",
      "security_deposit",
      "bedrooms",
      "bathrooms",
      "area_sqft",
      "floor_number",
      "total_floors",
      "parking_spaces",
      "available",
      "available_from",
      "age_years",
      "latitude",
      "longitude",
      "amenities",
      "visiting_hours",
      "user_id",
      "created_at",
      "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user" ]
  end
end
