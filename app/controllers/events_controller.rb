class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room

  def index
    @upcoming_events = @room.events.upcoming.includes(:rsvps, :user)
    @past_events = @room.events.past.includes(:rsvps, :user)
  end

  def calendar
    @month = (params[:month] || Date.today.strftime("%Y-%m"))
    @current_date = Date.strptime(@month, "%Y-%m")
    @first_day = @current_date.beginning_of_month
    @last_day = @current_date.end_of_month

    @events_by_day = @room.events
                           .where(starts_at: @first_day.beginning_of_day..@last_day.end_of_day)
                           .group_by { |e| e.starts_at.to_date }
  end

  def new
    @event = @room.events.new
  end

  def create
    @event = @room.events.new(event_params)
    @event.user = current_user

    if @event.save
      redirect_to room_events_path(@room), notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @event = @room.events.find(params[:id])

    if @event.user == current_user || current_user.admin?
      @event.destroy
      redirect_to room_events_path(@room), notice: "Event removed."
    else
      redirect_to room_events_path(@room), alert: "You can only remove your own events."
    end
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :starts_at)
  end
end