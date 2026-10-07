class VisitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_visit, except: :create

  # either party proposes a time; the other one confirms or declines
  def create
    inquiry = Inquiry.includes(:property).find(params[:inquiry_id])
    raise ActiveRecord::RecordNotFound unless inquiry.participant?(current_user)

    visit = inquiry.visits.new(params.require(:visit).permit(:scheduled_at, :note))
    visit.proposed_by = current_user
    if visit.save
      redirect_to inquiry_path(inquiry), notice: "Visit proposed. Waiting for the other person to confirm."
    else
      redirect_to inquiry_path(inquiry), alert: visit.errors.full_messages.to_sentence
    end
  end

  def confirm
    transition :confirm!, @visit.responder?(current_user), "Visit confirmed."
  end

  def decline
    transition :decline!, @visit.responder?(current_user), "Visit declined."
  end

  def cancel
    transition :cancel!, true, "Visit cancelled."
  end

  # owner marks a confirmed visit as done
  def complete
    transition :complete!, @inquiry.owner?(current_user), "Visit marked as completed."
  end

  private

  def set_visit
    @visit = Visit.includes(inquiry: :property).find(params[:id])
    @inquiry = @visit.inquiry
    raise ActiveRecord::RecordNotFound unless @inquiry.participant?(current_user)
  end

  def transition(action, allowed, notice)
    if allowed && @visit.public_send(action)
      redirect_to inquiry_path(@inquiry), notice: notice, status: :see_other
    else
      alert = @visit.errors.full_messages.to_sentence.presence || "That action isn't available."
      redirect_to inquiry_path(@inquiry), alert: alert, status: :see_other
    end
  end
end
