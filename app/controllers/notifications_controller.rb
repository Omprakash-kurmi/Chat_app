class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent.page(params[:page]).per(20)
  end

  # open a notification: mark it read, then go where it points
  def read
    note = current_user.notifications.find(params[:id])
    note.mark_read!
    redirect_to(note.path.presence || notifications_path, status: :see_other)
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, status: :see_other
  end
end
