class Api::ChatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user_message = Message.create!(
      content: params[:message],
      role: "user"
    )

    reply_text = "HUB9は受け取りました：「#{user_message.content}」"

    Message.create!(
      content: reply_text,
      role: "assistant"
    )

    render json: { reply: reply_text }
  end
end
