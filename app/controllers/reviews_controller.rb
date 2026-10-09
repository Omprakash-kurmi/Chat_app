class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :set_review, only: %i[update destroy]

  def create
    unless @property.reviewable_by?(current_user)
      return redirect_back fallback_location: property_path(@property),
                           alert: "Only customers whose inquiry was accepted can review this home."
    end
    @review = @property.reviews.new(review_params.merge(user: current_user))
    if @review.save
      redirect_to property_path(@property, anchor: "reviews"), notice: "Thanks for your review!", status: :see_other
    else
      redirect_to property_path(@property, anchor: "reviews"),
                  alert: @review.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def update
    if @review.update(review_params)
      redirect_to property_path(@property, anchor: "reviews"), notice: "Review updated.", status: :see_other
    else
      redirect_to property_path(@property, anchor: "reviews"),
                  alert: @review.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @review.destroy
    redirect_to property_path(@property, anchor: "reviews"), notice: "Review removed.", status: :see_other
  end

  def vote
    review = @property.reviews.find(params[:id])
    return head :forbidden if review.user_id == current_user.id

    helpful = params[:helpful] == "true"
    v = review.review_votes.find_or_initialize_by(user: current_user)
    if v.persisted? && v.helpful == helpful
      v.destroy                       # clicking the same button again removes the vote
    else
      v.helpful = helpful
      v.save
    end
    review.refresh_vote_counts!
    redirect_back fallback_location: property_path(@property, anchor: "reviews"), status: :see_other
  end

  private

  def set_property = @property = Property.find(params[:property_id])

  def set_review
    @review = @property.reviews.find(params[:id])
    head :forbidden unless @review.user_id == current_user.id || current_user.try(:admin?)
  end

  def review_params = params.require(:review).permit(:rating, :title, :comment)
end