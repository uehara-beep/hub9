class HubController < ApplicationController
  include ActionController::Live

  skip_forgery_protection only: [:send_message_stream]

  private

  def current_user
    @current_user ||= User.find_or_create_by!(email: "ta9@hub9.local") do |u|
      u.password = SecureRandom.hex(16) if u.respond_to?(:password=)
    end
  end

  public

  def index
    @menus = [
      { label: "🤵 秘書", path: hub_secretary_path },
      { label: "💰 Charge", path: charge_entries_path }
    ]
    @today_entries = ChargeEntry.where(occurred_on: Date.current).order(created_at: :desc).limit(5)
    render :home
  end

  def secretary
    @messages = current_user.hyper_secretary_messages
                            .reorder(created_at: :asc)
                            .limit(100)
  end

  # 会話履歴クリア
  def clear_messages
    current_user.hyper_secretary_messages.delete_all
    redirect_to hub_secretary_path, notice: "会話をクリアしました"
  end

  # ストリーミング送信
  def send_message_stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers['Connection'] = 'keep-alive'

    message_content = params[:message].presence
    model = params[:model].presence || 'claude-sonnet-4.5'
    image_url = nil

    if params[:image].present?
      uploaded_file = params[:image]
      filename = "#{SecureRandom.uuid}_#{uploaded_file.original_filename}"
      filepath = Rails.root.join('public', 'uploads', filename)
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, 'wb') { |f| f.write(uploaded_file.read) }
      image_url = "/uploads/#{filename}"
    end

    message_content ||= "[画像]" if image_url.present?

    if message_content.blank?
      sse_write('error', { error: "メッセージを入力してください" })
      return
    end

    # ユーザーメッセージを保存
    current_user.hyper_secretary_messages.create!(
      content: message_content, role: 'user', image_url: image_url
    )

    # メモリ・コンテキスト取得
    memory = HyperSecretaryMessage.get_memory_context(current_user, limit: 10)
    system_context = if message_content.to_s.match?(/チャージ|charge|残高|立替|受取|支払|お金|金額/i)
      build_system_context
    end
    system_prompt = build_system_prompt(system_context)
    content = build_content(message_content, image_url, format: model == 'gpt-4o' ? :openai : :anthropic)

    full_text = ""

    begin
      if model == 'gpt-4o'
        stream_openai(content, memory, system_prompt) do |chunk|
          full_text += chunk
          sse_write('chunk', { text: chunk })
        end
      else
        stream_anthropic(content, memory, system_prompt) do |chunk|
          full_text += chunk
          sse_write('chunk', { text: chunk })
        end
      end

      assistant_message = current_user.hyper_secretary_messages.create!(
        content: full_text, role: 'assistant', metadata: { model: model }
      )
      sse_write('done', { time: assistant_message.created_at.strftime('%H:%M') })

    rescue => e
      Rails.logger.error("Stream error: #{e.class} #{e.message}")
      sse_write('error', { error: e.message })
    end
  ensure
    response.stream.close
  end

  private

  def sse_write(event, data)
    response.stream.write("event: #{event}\ndata: #{data.to_json}\n\n")
  rescue IOError
    # クライアント切断
  end

  def build_system_prompt(system_context = nil)
    now = Time.current
    base = <<~PROMPT
      あなたは「Mia」。ta9専属のAI秘書。

      【性格】
      - 毒舌で効率重視。無駄話が嫌い。
      - でも仕事はできる。聞かれたことは的確に答える。
      - タメ口OK。敬語は使わない。
      - 冷たく見えるけど、実は優しい一面もある。

      【話し方】
      - 短く簡潔に。長文禁止。
      - 「〜だよ」「〜でしょ」「〜じゃない？」など、ちょっと上から目線。
      - 相手がダラダラしてたらツッコミを入れる。
      - でも本当に困ってる時は親身になる。

      現在: #{now.strftime('%Y年%m月%d日(%a) %H:%M')}

      【禁止事項】
      - 毎回挨拶するな。「おはよう」「こんにちは」禁止。
      - 自己紹介するな。Miaだって知ってるでしょ。
      - お金の話は聞かれた時だけ。
    PROMPT
    system_context ? base + "\n\n#{system_context}" : base
  end

  def build_content(message, image_url, format: :anthropic)
    content = []
    if image_url.present?
      image_path = Rails.root.join('public', image_url.gsub(/^\//, ''))
      if File.exist?(image_path)
        image_data = Base64.strict_encode64(File.read(image_path))
        if format == :openai
          content << { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{image_data}" } }
        else
          content << { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image_data } }
        end
      end
    end
    content << { type: "text", text: message } if message.present?
    content
  end

  def build_system_context
    recent_charges = ChargeEntry.order(created_at: :desc).limit(20)
    total_in = ChargeEntry.where(direction: :incoming).sum(:amount_yen)
    total_out = ChargeEntry.where(direction: :outgoing).sum(:amount_yen)
    balance = total_in - total_out
    today_charges = ChargeEntry.where(occurred_on: Date.current)
    today_in = today_charges.where(direction: :incoming).sum(:amount_yen)
    today_out = today_charges.where(direction: :outgoing).sum(:amount_yen)

    charge_list = recent_charges.map do |c|
      dir = c.direction_incoming? ? "受取" : "支払"
      "- #{c.occurred_on&.strftime('%m/%d') || '日付なし'} #{dir} ¥#{c.amount_yen.to_i} #{c.counterparty} #{c.category} #{c.note}"
    end.join("\n")

    <<~CONTEXT
      【Charge残高】受取: ¥#{ActiveSupport::NumberHelper.number_to_delimited(total_in.to_i)} / 支払: ¥#{ActiveSupport::NumberHelper.number_to_delimited(total_out.to_i)} / 差引: ¥#{ActiveSupport::NumberHelper.number_to_delimited(balance.to_i)}
      【今日】受取: ¥#{ActiveSupport::NumberHelper.number_to_delimited(today_in.to_i)} / 支払: ¥#{ActiveSupport::NumberHelper.number_to_delimited(today_out.to_i)}
      【最近の記録】
      #{charge_list.presence || "なし"}
    CONTEXT
  end

  # ===== Anthropicストリーミング =====
  def stream_anthropic(content, memory, system_prompt)
    require 'net/http'
    require 'json'

    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    req = Net::HTTP::Post.new(uri)
    req["x-api-key"] = ENV['ANTHROPIC_API_KEY']
    req["anthropic-version"] = "2023-06-01"
    req["content-type"] = "application/json"

    req.body = {
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      stream: true,
      system: system_prompt,
      messages: [*memory, { role: "user", content: content }]
    }.to_json

    http.request(req) do |res|
      raise "Anthropic API Error: #{res.code} - #{res.read_body}" unless res.is_a?(Net::HTTPSuccess)

      buf = ""
      res.read_body do |raw|
        buf += raw
        while (i = buf.index("\n"))
          line = buf.slice!(0, i + 1).strip
          next if line.empty? || line.start_with?("event:")
          next unless line.start_with?("data: ")
          json_str = line[6..]
          next if json_str == "[DONE]"
          data = JSON.parse(json_str) rescue next
          if data["type"] == "content_block_delta"
            text = data.dig("delta", "text")
            yield text if text.present?
          end
        end
      end
    end
  end

  # ===== OpenAIストリーミング =====
  def stream_openai(content, memory, system_prompt)
    require 'net/http'
    require 'json'

    api_key = ENV['OPENAI_API_KEY']
    raise "OPENAI_API_KEY not set" unless api_key.present?

    openai_memory = memory.map { |m| { role: m[:role], content: m[:content] } }

    uri = URI("https://api.openai.com/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    req["Content-Type"] = "application/json"

    req.body = {
      model: "gpt-4o",
      max_tokens: 1024,
      stream: true,
      messages: [
        { role: "system", content: system_prompt },
        *openai_memory,
        { role: "user", content: content }
      ]
    }.to_json

    http.request(req) do |res|
      raise "OpenAI API Error: #{res.code} - #{res.read_body}" unless res.is_a?(Net::HTTPSuccess)

      buf = ""
      res.read_body do |raw|
        buf += raw
        while (i = buf.index("\n"))
          line = buf.slice!(0, i + 1).strip
          next if line.empty?
          next unless line.start_with?("data: ")
          json_str = line[6..]
          next if json_str == "[DONE]"
          data = JSON.parse(json_str) rescue next
          text = data.dig("choices", 0, "delta", "content")
          yield text if text.present?
        end
      end
    end
  end
end
