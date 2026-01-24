require "net/http"
require "json"

module Hub9
  class AiChat
    def initialize(mode_label: "Hyper秘書")
      @mode_label = mode_label
    end

    def call(messages:, temperature: 0.7)
      api_key = ENV["OPENAI_API_KEY"].to_s
      raise "OPENAI_API_KEY is missing" if api_key.empty?

      uri = URI("https://api.openai.com/v1/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{api_key}"

      payload = {
        model: ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini"),
        temperature: temperature,
        messages: [
          { role: "system", content: Hub9::HyperSecretary.system_prompt(mode_label: @mode_label) },
          *messages
        ]
      }

      req.body = JSON.dump(payload)

      res = http.request(req)
      body = JSON.parse(res.body)

      if res.code.to_i >= 400
        raise "OpenAI error: #{res.code} #{body}"
      end

      body.dig("choices", 0, "message", "content").to_s
    end
  end
end
