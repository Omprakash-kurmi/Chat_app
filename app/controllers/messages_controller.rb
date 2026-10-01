class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    room = Room.find(params[:room_id])
    message = room.messages.new(message_params.merge(user: current_user))

    if message.save
      head :ok
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :image)
  end
end