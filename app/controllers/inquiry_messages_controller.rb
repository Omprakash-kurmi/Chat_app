class InquiryMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    inquiry = Inquiry.includes(:property).find(params[:inquiry_id])
    raise ActiveRecord::RecordNotFound unless inquiry.participant?(current_user)

    message = inquiry.messages.new(message_params.merge(user: current_user))
    if message.save
      respond_to do |format|
        # the message itself arrives through the live broadcast; the chat JS clears the input
        format.turbo_stream { head :no_content }
        format.html { redirect_to inquiry_path(inquiry) }
      end
    else
      redirect_to inquiry_path(inquiry), alert: message.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def message_params
    params.require(:inquiry_message).permit(:body, :image)
  end
end
