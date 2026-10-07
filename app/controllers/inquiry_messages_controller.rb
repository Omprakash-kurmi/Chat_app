class InquiryMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    inquiry = Inquiry.includes(:property).find(params[:inquiry_id])
    raise ActiveRecord::RecordNotFound unless inquiry.participant?(current_user)

    message = inquiry.messages.new(body: params.require(:inquiry_message)[:body], user: current_user)
    if message.save
      respond_to do |format|
        # the message itself arrives through the live broadcast; here we only reset the input
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("message_form",
                   partial: "inquiry_messages/form", locals: { inquiry: inquiry })
        end
        format.html { redirect_to inquiry_path(inquiry) }
      end
    else
      redirect_to inquiry_path(inquiry), alert: message.errors.full_messages.to_sentence, status: :see_other
    end
  end
end
