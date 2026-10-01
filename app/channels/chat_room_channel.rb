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
end