class AuthController < ApplicationController
  skip_before_action :require_ta9_login
  layout "auth"

  def login
  end

  def create
    if params[:login_id] == "ta9" && params[:password] == "0038"
      session[:ta9_logged_in] = true
      redirect_to root_path
    else
      flash.now[:alert] = "ログイン情報が違います"
      render :login
    end
  end

  def logout
    reset_session
    redirect_to login_path
  end
end
