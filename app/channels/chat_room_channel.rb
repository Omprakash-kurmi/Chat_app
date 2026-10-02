class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_for room
  end

  def speak(data)
    Message.create!(
      room_id: params[:room_id],
      user: current_user,
      content: data["content"]
    )
  end

  def typing
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      typing: true,
      user_id: current_user.id,
      user_name: current_user.email
    )
  end

  def stopped_typing
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      typing: false,
      user_id: current_user.id
    )
  end
end