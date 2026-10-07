class Inquiry < ApplicationRecord
  belongs_to :property
  belongs_to :user                       # the customer who is interested
  has_many :messages, class_name: "InquiryMessage", dependent: :destroy
  has_many :visits, dependent: :destroy

  enum :status, { pending: 0, accepted: 1, rejected: 2, withdrawn: 3, deal_done: 4 }

  STATUS_LABELS = {
    "pending"   => "Awaiting reply",
    "accepted"  => "Accepted",
    "rejected"  => "Declined",
    "withdrawn" => "Withdrawn",
    "deal_done" => "Deal done"
  }.freeze

  validates :message, presence: true, length: { maximum: 1500 }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validate :not_own_listing, :listing_open, :single_open_inquiry, on: :create

  after_create :start_conversation

  scope :active, -> { where(status: [ :pending, :accepted ]) }

  def status_label
    STATUS_LABELS.fetch(status, status.to_s.humanize)
  end

  # ---- who is who ----------------------------------------------------------
  def owner?(person)
    person.present? && property.user_id == person.id
  end

  def sender?(person)
    person.present? && user_id == person.id
  end

  def participant?(person)
    owner?(person) || sender?(person)
  end

  def active?
    pending? || accepted?
  end

  def chat_open?
    active?
  end

  # ---- workflow ------------------------------------------------------------
  def accept!
    return false unless pending?
    update!(status: :accepted, responded_at: Time.current)
    true
  end

  def reject!(note = nil)
    return false unless pending?
    transaction do
      update!(status: :rejected, owner_note: note.to_s.strip.presence, responded_at: Time.current)
      cancel_open_visits
    end
    true
  end

  def withdraw!
    return false unless active?
    transaction do
      update!(status: :withdrawn)
      cancel_open_visits
    end
    true
  end

  # Deal agreed: close the listing and politely decline everyone else.
  def close_deal!
    return false unless accepted?
    transaction do
      update!(status: :deal_done, closed_at: Time.current)
      property.update_columns(status: Property.statuses[:closed], available: false, updated_at: Time.current)
      property.inquiries.active.where.not(id: id).find_each do |other|
        other.update!(status: :rejected, owner_note: "This property is no longer available.",
                      responded_at: Time.current)
        other.cancel_open_visits
      end
      visits.where(status: :requested).update_all(status: Visit.statuses[:cancelled], updated_at: Time.current)
    end
    true
  end

  def cancel_open_visits
    visits.where(status: [ :requested, :confirmed ])
          .update_all(status: Visit.statuses[:cancelled], updated_at: Time.current)
  end

  private

  def not_own_listing
    if property && property.user_id == user_id
      errors.add(:base, "You can't send an inquiry for your own listing.")
    end
  end

  def listing_open
    unless property && property.published? && property.available?
      errors.add(:base, "This listing isn't accepting inquiries right now.")
    end
  end

  def single_open_inquiry
    if property_id && user_id && Inquiry.active.where(property_id: property_id, user_id: user_id).exists?
      errors.add(:base, "You already have an open inquiry for this property.")
    end
  end

  # the customer's first message becomes the first chat bubble
  def start_conversation
    messages.create!(user: user, body: message)
  end
end
