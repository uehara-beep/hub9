require "openai"

class OpenaiVisionOcr
  def initialize
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  # image_url: ActiveStorageのURL（public） or signed url
  def receipt(image_url:)
    prompt = <<~TXT
      あなたは経理OCRです。画像は日本のレシートです。
      次のJSONだけで返してください（説明文不要）:
      {
        "store_name": "",
        "date": "YYYY-MM-DD",
        "total": 0,
        "tax": 0,
        "payment_method": "",
        "items":[{"name":"","qty":1,"unit_price":0,"amount":0}],
        "notes":""
      }
      数値は可能なら整数。読めない場合はnull。
    TXT

    vision_json(prompt: prompt, image_url: image_url)
  end

  def business_card(image_url:)
    prompt = <<~TXT
      あなたは名刺OCRです。画像から次のJSONだけで返してください（説明文不要）:
      {
        "company": "",
        "department": "",
        "title": "",
        "name": "",
        "phone": "",
        "mobile": "",
        "email": "",
        "address": "",
        "website": "",
        "notes": ""
      }
      読めない場合は空文字。
    TXT

    vision_json(prompt: prompt, image_url: image_url)
  end

  private

  def vision_json(prompt:, image_url:)
    res = @client.chat(
      parameters: {
        model: ENV.fetch("OPENAI_OCR_MODEL", "gpt-4o-mini"),
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "必ずJSONのみで出力してください。" },
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: image_url } }
            ]
          }
        ]
      }
    )

    res.dig("choices", 0, "message", "content")
  end
end
