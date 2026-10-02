class RoomMailer < ApplicationMailer
  def invitation(user, room)
    @user = user
    @room = room
    @room_url = room_url(@room)

    mail(to: @user.email, subject: "You're invited to \"#{@room.name}\" on Chat_App")
  end
end