class Vendor::DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    props = Property.where(user_id: current_user.id)
    ids   = props.select(:id)

    @total             = props.count
    @published         = props.where(status: "published").count
    @pending_listings  = props.where(status: "pending").count
    @by_type           = props.group(:listing_type).count.transform_keys(&:to_s)

    inquiries          = Inquiry.where(property_id: ids)
    @inquiry_total     = inquiries.count
    @new_inquiries     = inquiries.where(status: :pending).count
    @recent_inquiries  = inquiries.includes(:property, :user).order(created_at: :desc).limit(5)

    @week = (6.days.ago.to_date..Date.current).map do |day|
      { label: day.strftime("%a"), count: inquiries.where(created_at: day.all_day).count }
    end

    reviews            = Review.where(property_id: ids)
    @review_total      = reviews.count
    @avg_rating        = reviews.average(:rating)&.round(1)
    @recent_reviews    = reviews.includes(:user, :property).order(created_at: :desc).limit(4)

    @latest_properties = props.order(created_at: :desc).limit(6)
  end
end