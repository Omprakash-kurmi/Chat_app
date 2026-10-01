class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user

  has_one_attached :image

  validates :content, presence: true, unless: -> { image.attached? }

  def self.ransackable_attributes(auth_object = nil)
    ["content", "created_at", "updated_at", "id", "room_id", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["room", "user"]
  end

  after_create_commit :broadcast_message

  private

  def broadcast_message
    ChatRoomChannel.broadcast_to(
      room,
      html: ApplicationController.render(partial: "messages/message", locals: { message: self })
    )
  end
end