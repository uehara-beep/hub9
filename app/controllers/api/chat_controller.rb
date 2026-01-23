class Api::ChatController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    payload = JSON.parse(request.raw_post) rescue {}
    mode = payload["mode"].to_s
    message = payload["message"].to_s

    # /コマンドが来たら、modeや本文を差し替え
    applied = Hub9::Assistant.apply_slash_command(message)
    mode = applied[:mode] if applied[:mode]
    message = applied[:text]

    system = Hub9::Assistant.mode_system(mode)

    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    resp = client.chat(
      parameters: {
        model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"),
        messages: [
          { role: "system", content: system },
          { role: "user", content: message }
        ]
      }
    )

    content = resp.dig("choices", 0, "message", "content") || ""
    render json: { reply: content, mode: mode.presence || "default" }
  rescue => e
    Rails.logger.error("[api/chat] #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
    render json: { error: e.message }, status: 500
  end
end
