class Room < ApplicationRecord
  has_many :messages, dependent: :destroy
  validates :name, presence: true

  after_create_commit :notify_all_users

  def self.ransackable_attributes(auth_object = nil)
    ["name", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["messages"]
  end

  private

  def notify_all_users
    User.find_each do |user|
      RoomMailer.invitation(user, self).deliver_later
    end
  end
end