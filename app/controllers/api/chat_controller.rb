class Api::ChatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user_message = Message.create!(
      content: params[:message],
      role: "user"
    )

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    history = Message.order(:created_at).last(10).map do |m|
      { role: m.role, content: m.content }
    end

    response = client.chat(
      parameters: {
        model: "gpt-4.1-mini",
        messages: history
      }
    )

    reply_text = response.dig("choices", 0, "message", "content")

    Message.create!(
      content: reply_text,
      role: "assistant"
    )

    render json: { reply: reply_text }
  end
end
