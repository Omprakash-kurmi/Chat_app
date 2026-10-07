class Visit < ApplicationRecord
  SLOT_MINUTES = 60

  belongs_to :inquiry
  belongs_to :property
  belongs_to :proposed_by, class_name: "User"

  enum :status, { requested: 0, confirmed: 1, declined: 2, cancelled: 3, completed: 4 }

  before_validation :copy_property, on: :create

  validates :scheduled_at, presence: true
  validates :note, length: { maximum: 200 }
  validate :in_the_future, :inquiry_accepted, on: :create
  validate :no_clash, if: :confirmed?

  scope :upcoming, -> {
    where(status: [ :requested, :confirmed ]).where("scheduled_at >= ?", Time.current).order(:scheduled_at)
  }

  # the person who did NOT propose the time is the one who answers
  def responder?(person)
    person.present? && inquiry.participant?(person) && person.id != proposed_by_id
  end

  def confirm!
    requested? && update(status: :confirmed)
  end

  def decline!
    requested? && update(status: :declined)
  end

  def cancel!
    (requested? || confirmed?) && update(status: :cancelled)
  end

  def complete!
    confirmed? && update(status: :completed)
  end

  private

  def copy_property
    self.property_id ||= inquiry && inquiry.property_id
  end

  def in_the_future
    errors.add(:scheduled_at, "must be in the future") if scheduled_at && scheduled_at <= Time.current
  end

  def inquiry_accepted
    unless inquiry && inquiry.accepted?
      errors.add(:base, "Visits can only be scheduled after the owner accepts the inquiry.")
    end
  end

  # one confirmed visit per property per hour slot
  def no_clash
    return unless scheduled_at
    window = (scheduled_at - (SLOT_MINUTES - 1).minutes)..(scheduled_at + (SLOT_MINUTES - 1).minutes)
    clash = Visit.confirmed.where(property_id: property_id, scheduled_at: window)
    clash = clash.where.not(id: id) if persisted?
    errors.add(:base, "Another visit is already confirmed around that time. Please pick a different slot.") if clash.exists?
  end
end
