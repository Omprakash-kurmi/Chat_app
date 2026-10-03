class Event < ApplicationRecord
  belongs_to :room
  belongs_to :user
  has_many :rsvps, dependent: :destroy

  validates :title, presence: true
  validates :starts_at, presence: true

  scope :upcoming, -> { where("starts_at >= ?", Time.zone.now).order(:starts_at) }
  scope :past, -> { where("starts_at < ?", Time.zone.now).order(starts_at: :desc) }

  def rsvp_for(user)
    rsvps.find_by(user: user)
  end

  def going_count
    rsvps.where(status: "going").count
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "title", "description", "starts_at", "created_at", "updated_at", "id", "room_id", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "room", "user", "rsvps" ]
  end
end
