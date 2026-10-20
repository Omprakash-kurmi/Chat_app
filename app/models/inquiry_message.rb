class InquiryMessage < ApplicationRecord
  belongs_to :inquiry, touch: true
  belongs_to :user

  has_one_attached :image

  validate :conversation_open, :sender_belongs, on: :create
  validates :body, presence: true, unless: -> { image.attached? }
  # validate :image_type_ok

  after_create_commit :broadcast_to_conversation

  def from_owner?
    user_id == inquiry.property.user_id
  end

  def image_ok
    errors.add(:image, "must be a JPG, PNG, WEBP or GIF") unless image.content_type.in?(%w[image/jpeg image/png image/webp image/gif])
    errors.add(:image, "must be under 5 MB") if image.byte_size > 5.megabytes
  end

  private

  def image_type_ok
    return unless image.attached?

    unless image.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:image, "must be a JPG, PNG, GIF or WebP photo")
    end
    errors.add(:image, "is too large (max 5 MB)") if image.byte_size > 5.megabytes
  end

  def conversation_open
    errors.add(:base, "This conversation is closed.") unless inquiry && inquiry.chat_open?
  end

  def sender_belongs
    errors.add(:base, "You can't post in this conversation.") unless inquiry && inquiry.participant?(user)
  end

  def broadcast_to_conversation
    broadcast_append_to(
      [ inquiry, :messages ],
      target: "inquiry_#{inquiry.id}_messages",
      partial: "inquiry_messages/message",
      locals: { message: self }
    )
  end
end
