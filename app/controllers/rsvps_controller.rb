class RsvpsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = Event.find(params[:event_id])
    rsvp = event.rsvps.find_or_initialize_by(user: current_user)
    rsvp.status = params[:status]
    rsvp.save

    redirect_to room_events_path(event.room)
  end

  def update
    rsvp = Rsvp.find(params[:id])

    if rsvp.user == current_user
      rsvp.update(status: params[:status])
    end

    redirect_to room_events_path(rsvp.event.room)
  end
end