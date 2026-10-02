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

  # ---- Call signaling ----

  def call_offer(data)
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      call_event: "offer",
      call_type: data["call_type"], # "voice" or "video"
      from_user_id: current_user.id,
      from_user_name: current_user.display_name,
      sdp: data["sdp"]
    )
  end

  def call_answer(data)
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      call_event: "answer",
      from_user_id: current_user.id,
      sdp: data["sdp"]
    )
  end

  def call_ice_candidate(data)
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      call_event: "ice_candidate",
      from_user_id: current_user.id,
      candidate: data["candidate"]
    )
  end

  def call_hangup
    ChatRoomChannel.broadcast_to(
      Room.find(params[:room_id]),
      call_event: "hangup",
      from_user_id: current_user.id
    )
  end
end
