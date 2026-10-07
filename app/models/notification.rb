class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def unread?
    read_at.nil?
  end

  def mark_read!
    update_columns(read_at: Time.current) if unread?
  end
end
