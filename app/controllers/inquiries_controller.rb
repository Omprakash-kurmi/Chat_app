class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, only: %i[show accept reject withdraw close_deal]
  before_action :require_owner!, only: %i[accept reject close_deal]
  before_action :require_sender!, only: :withdraw

  # Inbox: "received" = people interested in MY listings, "sent" = inquiries I sent
  def index
    @box = params[:box].presence_in(%w[received sent]) || (current_user.vendor? ? "received" : "sent")
    base = if @box == "received"
      Inquiry.where(property_id: current_user.properties.select(:id))
    else
      current_user.inquiries
    end
    base = base.where(property_id: params[:property_id]) if @box == "received" && params[:property_id].present?

    @counts = base.group(:status).count
    scope = Inquiry.statuses.key?(params[:status]) ? base.where(status: params[:status]) : base
    @inquiries = scope.includes(:user, property: [ :user, { photos_attachments: :blob } ])
                      .order(updated_at: :desc).limit(100).to_a
    @upcoming_visits = Visit.upcoming.where(inquiry_id: @inquiries.map(&:id)).group_by(&:inquiry_id)
    @property_filter = Property.find_by(id: params[:property_id], user_id: current_user.id) if params[:property_id].present?
  end

  def show
    @owner_view = @inquiry.owner?(current_user)
    @messages = @inquiry.messages.includes(:user).order(:created_at)
    @visits = @inquiry.visits.includes(:proposed_by).order(:scheduled_at)
  end

  # customer sends an inquiry from the property page
  def create
    @property = Property.published.find(params[:property_id])
    @inquiry = @property.inquiries.new(params.require(:inquiry).permit(:message, :phone))
    @inquiry.user = current_user
    if @inquiry.save
      redirect_to @inquiry, notice: "Inquiry sent. The owner will get back to you soon."
    else
      redirect_to property_path(@property), alert: @inquiry.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to property_path(@property), alert: "You already have an open inquiry for this property."
  end

  def accept
    respond_with_result @inquiry.accept!, "Inquiry accepted. You can now chat and schedule a visit."
  end

  def reject
    respond_with_result @inquiry.reject!(params[:owner_note]), "Inquiry declined."
  end

  def withdraw
    respond_with_result @inquiry.withdraw!, "Inquiry withdrawn."
  end

  def close_deal
    respond_with_result @inquiry.close_deal!, "Deal marked as done. The listing is now closed."
  end

  private

  def set_inquiry
    @inquiry = Inquiry.includes(:property, :user).find(params[:id])
    # strangers get a 404, not a "forbidden" hint that the inquiry exists
    raise ActiveRecord::RecordNotFound unless @inquiry.participant?(current_user)
  end

  def require_owner!
    head :forbidden unless @inquiry.owner?(current_user)
  end

  def require_sender!
    head :forbidden unless @inquiry.sender?(current_user)
  end

  def respond_with_result(ok, notice)
    if ok
      redirect_to @inquiry, notice: notice, status: :see_other
    else
      redirect_to @inquiry, alert: "That action isn't available for this inquiry right now.", status: :see_other
    end
  end
end
