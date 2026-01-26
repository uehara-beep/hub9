require "net/http"
require "json"

module HyperSecretary
  class OpenAi
    ENDPOINT = "https://api.openai.com/v1/chat/completions"

    def self.chat(system:, user:, temperature: 0.2, model: nil)
      key = ENV["OPENAI_API_KEY"].to_s
      raise "OPENAI_API_KEY missing" if key.empty?

      uri = URI(ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{key}"
      req["Content-Type"] = "application/json"

      payload = {
        model: (model || ENV["OPENAI_MODEL"] || "gpt-4o-mini"),
        temperature: temperature,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user }
        ]
      }

      req.body = JSON.generate(payload)
      res = http.request(req)
      raise "OpenAI error: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      data.dig("choices", 0, "message", "content").to_s
    end
  end
end
