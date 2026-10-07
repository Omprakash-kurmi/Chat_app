module PropertyWorkflow
  extend ActiveSupport::Concern

  STATUS_LABELS = {
    "pending"   => "Awaiting verification",
    "published" => "Published",
    "rejected"  => "Needs changes",
    "closed"    => "Closed (deal done)"
  }.freeze

  included do
    enum :status, { pending: 0, published: 1, rejected: 2, closed: 3 }

    has_many :inquiries, dependent: :destroy
    has_many :visits, dependent: :destroy

    # what customers can search: verified, and still available
    scope :listed, -> { published.available }
  end

  class_methods do
    # needed by ActiveAdmin / Ransack filters
    def ransackable_attributes(_auth_object = nil)
      %w[id title city locality pincode status listing_type property_type price created_at verified_at]
    end

    def ransackable_associations(_auth_object = nil)
      []
    end
  end

  def status_label
    STATUS_LABELS.fetch(status, status.to_s.humanize)
  end

  # Admin approves (also works on a previously rejected listing)
  def approve!
    return false unless pending? || rejected?
    update_columns(status: self.class.statuses[:published], rejection_reason: nil,
                   verified_at: Time.current, updated_at: Time.current)
    true
  end

  def reject!(reason = nil)
    return false unless pending? || published?
    update_columns(status: self.class.statuses[:rejected],
                   rejection_reason: reason.to_s.strip.presence || "Does not meet our listing guidelines.",
                   updated_at: Time.current)
    true
  end

  # Owner puts a closed listing back on the market (e.g. tenant moved out)
  def reopen!
    return false unless closed?
    update_columns(status: self.class.statuses[:published], available: true, updated_at: Time.current)
    true
  end
end
