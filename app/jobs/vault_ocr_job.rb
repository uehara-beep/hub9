class VaultOcrJob < ApplicationJob
  queue_as :default

  def perform(vault_entry_id)
    entry = VaultEntry.find(vault_entry_id)
    return unless entry.receipt.attached?

    entry.update!(ocr_status: "running", ocr_error: nil)

    image_url = Rails.application.routes.url_helpers.rails_blob_url(
      entry.receipt,
      host: ENV.fetch("APP_HOST", "localhost:3000")
    )

    require "openai"
    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

    prompt = <<~PROMPT
      あなたは領収書OCRです。次のJSONだけを返してください:
      {
        "type":"receipt",
        "merchant":"",
        "date":"",
        "total":0,
        "currency":"JPY",
        "items":[{"name":"","qty":1,"price":0}],
        "raw_text":""
      }
      dateは YYYY-MM-DD。合計が無い時は0。
    PROMPT

    res = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: image_url } }
          ]}
        ]
      }
    )

    json_text = res.dig("choices", 0, "message", "content").to_s
    parsed = JSON.parse(json_text) rescue { "type" => "receipt", "raw_text" => json_text }

    entry.update!(
      parsed_json: parsed,
      ocr_status: "done"
    )
  rescue => e
    entry&.update!(ocr_status: "failed", ocr_error: "#{e.class}: #{e.message}")
    raise
  end
end
