class Property < ApplicationRecord
  include PropertyWorkflow
  AMENITIES = [
    "Lift", "Power backup", "24x7 security", "CCTV", "Gym", "Swimming pool", "Clubhouse", "Garden",
    "Children's play area", "24x7 water supply", "Gas pipeline", "Intercom", "Visitor parking",
    "Rainwater harvesting", "Pet friendly", "Wi-Fi ready"
  ].freeze

  # LAND: units are stored as "how many sq ft is one unit"
  LAND_AREA_UNITS   = { "sqft" => "1", "sqyd" => "9", "sqm" => "10.7639", "acre" => "43560" }.freeze
  AREA_UNIT_LABELS  = { "sqft" => "sq ft", "sqyd" => "sq yd", "sqm" => "sq m", "acre" => "acres" }.freeze
  FACINGS     = %w[North East South West North-East North-West South-East South-West].freeze
  OWNERSHIPS  = [ "Freehold", "Leasehold", "Power of attorney", "Co-operative society" ].freeze
  APPROVALS   = [ "Municipal / local authority", "DTCP / town planning", "RERA registered",
                  "Gram panchayat", "Not yet approved" ].freeze

  belongs_to :user
  has_many_attached :photos
  has_many_attached :videos
  has_many_attached :gallery

  has_many :inquiries, dependent: :destroy
  has_many :inquiry_messages, dependent: :destroy
  has_many :proposed_visits, class_name: "Visit", foreign_key: :proposed_by_id, dependent: :destroy
  has_many :reviews, dependent: :destroy

  enum :listing_type,  { rent: 0, buy: 1, land: 2 }          # LAND: third option
  enum :property_type, { apartment: 0, house: 1, villa: 2, plot: 3, studio: 4, penthouse: 5, commercial: 6 }
  enum :furnishing,    { unfurnished: 0, semi_furnished: 1, furnished: 2 }
  enum :poster_type,   { owner: 0, agent: 1 }
  enum :land_type,     { residential: 0, agricultural: 1, commercial: 2, industrial: 3 }, prefix: :land  # LAND

  before_validation :tidy
  before_save :restore_availability, if: -> { status_changed? && published? }

  validates :title, :address, :city, :contact_phone, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :pincode, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, allow_blank: true
  validates :security_deposit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :photos_valid, :videos_valid
  validate :gallery_ok

  # LAND: extra rules only for land listings
  with_options if: :land? do
    validates :land_type, presence: { message: "– choose the land type" }
    validates :land_area, numericality: { greater_than: 0 }
    validates :area_unit, inclusion: { in: LAND_AREA_UNITS.keys }
    validates :facing, inclusion: { in: FACINGS }, allow_blank: true
    validates :road_width_ft, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :plot_length, :plot_width, numericality: { greater_than: 0 }, allow_nil: true
  end

  scope :available, -> { where(available: true) }

  def average_rating
    reviews.average(:rating).to_f.round(1)
  end

  # def reviewable_by?(user)
  #   return false unless user&.customer?
  #   return false if user_id == user.id            # owner can't review own home
  #   inquiries.where(user_id: user.id, status: %w[accepted closed]).exists?
  # end

  # def verified_reviewer_ids
  #     inquiries.where(status: %w[accepted closed]).pluck(:user_id)
  #   rescue ActiveRecord::StatementInvalid, NoMethodError
  #     []
  # end

  def reviewable_by?(user)
    return false if user.nil?
    return false if user_id == user.id                       # vendors can't review their own listing
    inquiries.where(user_id: user.id, status: :accepted).exists?
  end

  def verified_reviewer_ids
    inquiries.where(status: :accepted).pluck(:user_id)
  end

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

    # LAND: area filters understand the chosen unit (sq ft by default)
    factor = LAND_AREA_UNITS.fetch(f["area_unit"].to_s, "1").to_d
    scope = scope.where("area_sqft >= ?", (f["min_area"].to_d * factor).round) if f["min_area"].present?
    scope = scope.where("area_sqft <= ?", (f["max_area"].to_d * factor).round) if f["max_area"].present?
    scope = scope.where("parking_spaces > 0") if f["parking"].to_s == "1"

    # LAND filters
    kinds = Array(f["land_types"]).reject(&:blank?) & land_types.keys
    scope = scope.where(land_type: kinds) if kinds.any?
    scope = scope.where(facing: f["facing"]) if f["facing"].present? && FACINGS.include?(f["facing"])
    scope = scope.where(boundary_wall: true) if f["boundary_wall"].to_s == "1"
    scope = scope.where(corner_plot: true) if f["corner_plot"].to_s == "1"
    scope = scope.where("road_width_ft >= ?", f["min_road"].to_i) if f["min_road"].present?

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

  # LAND helpers
  def listing_label
    { "rent" => "For rent", "buy" => "For sale", "land" => "Land / Plot" }[listing_type]
  end

  def land_area_label
    return if land_area.blank?
    "#{ActiveSupport::NumberHelper.number_to_delimited(trim_number(land_area))} #{AREA_UNIT_LABELS.fetch(area_unit, 'sq ft')}"
  end

  def plot_dimensions
    return unless plot_length && plot_width
    "#{trim_number(plot_length)} × #{trim_number(plot_width)} ft"
  end

  def land_kind_label
    land_type.present? ? "#{land_type.humanize} land" : "Land"
  end

  private

  def trim_number(n)
    f = n.to_f
    f == f.to_i ? f.to_i : f
  end

  def restore_availability
    self.available = true
  end

  def gallery_ok
    return unless gallery.attached?
    gallery.each do |img|
      errors.add(:gallery, "can only contain images") unless img.content_type.to_s.start_with?("image/")
      errors.add(:gallery, "images must be under 8 MB each") if img.byte_size > 8.megabytes
    end
  end

  def tidy
    self.amenities = Array(amenities).reject(&:blank?) & AMENITIES
    self.pincode = pincode.to_s.strip.presence
    self.security_deposit = nil unless rent?

    if land?
      self.property_type = :plot
      self.area_sqft = (land_area.to_d * LAND_AREA_UNITS.fetch(area_unit.to_s, "1").to_d).round if land_area.present?
      self.bedrooms = nil
      self.bathrooms = nil
      self.furnishing = :unfurnished
      self.parking_spaces = 0
      self.floor_number = nil
      self.total_floors = nil
      self.age_years = nil
    end
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
    %w[
      id title description address locality city pincode contact_name contact_phone
      listing_type property_type furnishing poster_type price security_deposit bedrooms bathrooms
      area_sqft floor_number total_floors parking_spaces available available_from age_years
      latitude longitude amenities visiting_hours user_id created_at updated_at
      land_type land_area area_unit plot_length plot_width facing road_width_ft
      boundary_wall corner_plot ownership_type approval_authority
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user" ]
  end
end