class RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: [ :new, :create ]

  def index
    @rooms = Room.all.order(:name)
    @last_messages = Message.where(room_id: @rooms.ids)
                             .order(created_at: :desc)
                             .group_by(&:room_id)
                             .transform_values(&:first)
    @message_counts = Message.where(room_id: @rooms.ids).group(:room_id).count
    @messages_today = Message.where("created_at >= ?", Time.zone.now.beginning_of_day).count
  end

  def show
    @room = Room.find(params[:id])
    @messages = @room.messages.includes(:user).order(:created_at).last(50)
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      redirect_to @room, notice: "Room created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def room_params
    params.require(:room).permit(:name)
  end

  def require_admin
    unless current_user.admin?
      redirect_to rooms_path, alert: "Only admins can create rooms."
    end
  end
end
