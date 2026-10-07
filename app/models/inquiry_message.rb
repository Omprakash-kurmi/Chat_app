class InquiryMessage < ApplicationRecord
  belongs_to :inquiry, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }
  validate :conversation_open, :sender_belongs, on: :create

  # live update for everyone who has the conversation open (Turbo Streams over Action Cable)
  after_create_commit :broadcast_to_conversation

  def from_owner?
    user_id == inquiry.property.user_id
  end

  private

  def conversation_open
    errors.add(:base, "This conversation is closed.") unless inquiry && inquiry.chat_open?
  end

  def sender_belongs
    errors.add(:base, "You can't post in this conversation.") unless inquiry && inquiry.participant?(user)
  end

  # def broadcast_to_conversation
  #   broadcast_append_to [ inquiry, :messages ],
  #                       target: "inquiry_#{inquiry_id}_messages",
  #                       partial: "inquiry_messages/message",
  #                       locals: { message: self }
  # end
  def broadcast_to_conversation
    broadcast_append_to(
      [ inquiry, :messages ],
      target: "inquiry_#{inquiry.id}_messages",
      partial: "inquiry_messages/message",
      locals: { message: self }
    )
  end
end
