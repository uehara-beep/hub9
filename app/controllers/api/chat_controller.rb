class Api::ChatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    message = params[:message]

    render json: {
      reply: "HUB9は受け取りました：「#{message}」"
    }
  end
end
