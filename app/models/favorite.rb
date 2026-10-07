class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :property

  validates :property_id, uniqueness: { scope: :user_id }
  validate  :not_own_listing

  private

  def not_own_listing
    errors.add(:base, "You can't favorite your own listing") if property && property.user_id == user_id
  end
end
