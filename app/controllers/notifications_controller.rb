class NotificationsController < ApplicationController
  def index
    @notifications = Notification.order(created_at: :desc).limit(50)
  end

  def read
    n = Notification.find(params[:id])
    n.update!(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end
end
