class Api::ChatController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    text = params[:message].to_s
    history = (session[:hub9_chat_history] ||= [])
    history << { role: "user", content: text }
    history = history.last(12)

    ai = Hub9::AiChat.new(mode_label: "Hyper秘書")
    is_record = Hub9::HyperSecretary.record_intent?(text)
    temperature = is_record ? 0.2 : 0.8

    answer = ai.call(
      messages: history.map { |m| { role: m[:role], content: m[:content] } },
      temperature: temperature
    )

    history << { role: "assistant", content: answer }
    session[:hub9_chat_history] = history.last(12)

    render json: { reply: answer, record_intent: is_record }
  rescue => e
    Rails.logger.error("[api/chat] #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
    render json: { error: e.message }, status: 500
  end
end
