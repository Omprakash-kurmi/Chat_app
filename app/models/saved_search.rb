# A customer's saved filters. When a matching listing is published we notify them.
class SavedSearch < ApplicationRecord
  belongs_to :user

  MAX_PER_USER = 10
  SCALAR_KEYS  = %w[q min_price max_price bedrooms min_area max_area parking available_by].freeze
  ARRAY_KEYS   = %w[property_types furnishings amenities].freeze
  FILTER_KEYS  = (SCALAR_KEYS + ARRAY_KEYS).freeze

  validates :name, presence: true, length: { maximum: 120 }
  validates :listing_type, inclusion: { in: %w[rent buy] }
  validate  :needs_a_filter
  validate  :under_limit, on: :create

  scope :alerting, -> { where(notify: true) }

  # Turns raw request params into the clean hash we store (blank values dropped).
  def self.clean_filters(params)
    out = {}
    SCALAR_KEYS.each do |key|
      value = params[key].to_s.strip
      value = "" if key == "parking" && value != "1"
      out[key] = value if value.present?
    end
    ARRAY_KEYS.each do |key|
      values = Array(params[key]).map { |v| v.to_s.strip }.reject(&:blank?)
      out[key] = values if values.any?
    end
    out
  end

  # Same results the customer saw when they pressed "Save this search".
  def results
    Property.listed.where(listing_type: listing_type).matching(ActionController::Parameters.new(filters))
  end

  def matches?(property)
    property.listing_type.to_s == listing_type && results.where(id: property.id).exists?
  end

  # Params for homes_path(...) so "View results" reopens the exact search.
  def query_params
    filters.symbolize_keys.merge(listing_type: listing_type)
  end

  # Human readable chips: ["For rent", "📍 Mumbai", "Up to ₹30,000", "2+ beds"]
  def summary
    money = ActionController::Base.helpers
    inr = ->(n) { money.number_to_currency(n, unit: "₹", precision: 0, delimiter_pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/) }
    f = filters
    chips = [ listing_type == "rent" ? "For rent" : "For sale" ]
    chips << "📍 #{f['q']}" if f["q"].present?
    if f["min_price"].present? && f["max_price"].present?
      chips << "#{inr.call(f['min_price'])} – #{inr.call(f['max_price'])}"
    elsif f["max_price"].present?
      chips << "Up to #{inr.call(f['max_price'])}"
    elsif f["min_price"].present?
      chips << "From #{inr.call(f['min_price'])}"
    end
    chips << "#{f['bedrooms']}+ beds" if f["bedrooms"].present?
    chips.concat(Array(f["property_types"]).map(&:humanize))
    chips.concat(Array(f["furnishings"]).map { |x| x == "semi_furnished" ? "Semi-furnished" : x.humanize })
    if f["min_area"].present? || f["max_area"].present?
      chips << "#{f['min_area'].presence || 0}–#{f['max_area'].presence || 'any'} sq ft"
    end
    chips << "🚗 Parking" if f["parking"] == "1"
    chips << "Available by #{f['available_by']}" if f["available_by"].present?
    chips.concat(Array(f["amenities"]))
    chips
  end

  # Short default title, e.g. "Mumbai · up to ₹30,000 · 2+ beds"
  def self.default_name(listing_type, filters)
    probe = new(listing_type: listing_type, filters: filters)
    parts = probe.summary.drop(1).first(3).map { |c| c.sub("📍 ", "") }
    base = listing_type == "rent" ? "Rent" : "Buy"
    parts.empty? ? base : "#{base}: #{parts.join(' · ')}"
  end

  private

  def needs_a_filter
    errors.add(:base, "Choose at least one filter (location, budget, bedrooms…) before saving a search") if filters.blank?
  end

  def under_limit
    if user && user.saved_searches.count >= MAX_PER_USER
      errors.add(:base, "You can keep up to #{MAX_PER_USER} saved searches. Delete one to add another.")
    end
  end
end
