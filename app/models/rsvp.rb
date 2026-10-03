class Rsvp < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :status, inclusion: { in: %w[going maybe not_going] }
  validates :user_id, uniqueness: { scope: :event_id }

  def self.ransackable_attributes(auth_object = nil)
    [ "status", "created_at", "updated_at", "id", "event_id", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "event", "user" ]
  end
end
