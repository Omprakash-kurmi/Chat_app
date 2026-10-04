class Property < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  enum :listing_type, { rent: 0, buy: 1 }
  enum :property_type, { apartment: 0, house: 1, villa: 2, plot: 3 }

  validates :title, :address, :city, :contact_phone, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :photos_valid

  scope :available, -> { where(available: true) }

  private

  def photos_valid
    errors.add(:photos, "– add at least one photo") if new_record? && !photos.attached?
    errors.add(:photos, "– maximum is 8") if photos.size > 8
    photos.each do |p|
      errors.add(:photos, "must be images") unless p.content_type.to_s.start_with?("image/")
      errors.add(:photos, "must be under 5 MB") if p.byte_size > 5.megabytes
    end
  end
end
