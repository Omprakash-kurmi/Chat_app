class Review < ApplicationRecord
  belongs_to :user
  belongs_to :property

  has_many :review_votes, dependent: :destroy

  validates :rating, presence: true, inclusion: { in: 1..5, message: "must be 1 to 5 stars" }
  validates :title,   length: { maximum: 80 }
  validates :comment, length: { maximum: 1000 }
  validates :user_id, uniqueness: { scope: :property_id, message: "has already reviewed this home" }

  scope :newest, -> { order(created_at: :desc) }

  def self.sorted(by)
    case by
    when "latest"   then order(created_at: :desc)
    when "positive" then order(rating: :desc, helpful_count: :desc)
    when "negative" then order(rating: :asc,  helpful_count: :desc)
    else                 order(helpful_count: :desc, created_at: :desc)
    end
  end

  def refresh_vote_counts!
    update_columns(helpful_count:     review_votes.where(helpful: true).count,
               not_helpful_count: review_votes.where(helpful: false).count)
  end

  def self.ransackable_attributes(_auth = nil) = %w[id rating title comment user_id property_id created_at]
  def self.ransackable_associations(_auth = nil) = %w[user property]
end
