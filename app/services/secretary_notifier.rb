require "net/http"
require "json"

class SecretaryNotifier
  def self.slack(text)
    return unless ENV["SLACK_WEBHOOK_URL"]

    uri = URI(ENV["SLACK_WEBHOOK_URL"])
    Net::HTTP.post(
      uri,
      { text: text }.to_json,
      "Content-Type" => "application/json"
    )
  rescue => e
    Rails.logger.error("[SlackNotify] #{e.message}")
  end

  def self.line(text)
    return unless ENV["LINE_CHANNEL_TOKEN"] && ENV["LINE_USER_ID"]

    uri = URI("https://api.line.me/v2/bot/message/push")
    Net::HTTP.post(
      uri,
      {
        to: ENV["LINE_USER_ID"],
        messages: [{ type: "text", text: text }]
      }.to_json,
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV['LINE_CHANNEL_TOKEN']}"
      }
    )
  rescue => e
    Rails.logger.error("[LineNotify] #{e.message}")
  end
end
