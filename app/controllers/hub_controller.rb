class HubController < ApplicationController
  # =============================================
  # Secretary（秘書）: AIチャット
  # - 会話ベースで何でも相談
  # - 送金/立替を検出 → Charge自動記録
  # - メインの入り口
  # =============================================
  # ta9ログインを使用（Devise不要）

  private

  # Deviseの代わりにta9ユーザーを返す
  def current_user
    @current_user ||= User.find_or_create_by!(email: "ta9@hub9.local") do |u|
      u.password = SecureRandom.hex(16) if u.respond_to?(:password=)
    end
  end

  public

  def index
    # シンプルなメニュー構成
    @menus = [
      { label: "🤵 秘書", path: hub_secretary_path },
      { label: "💰 Charge", path: charge_entries_path }
    ]
    @today_entries = ChargeEntry.where(occurred_on: Date.current).order(created_at: :desc).limit(5)
    render :home
  end

  def secretary
    # 秘書画面（古い順 = 最新が下、LINEスタイル）
    # reorderでdefault_scopeを上書き
    @messages = current_user.hyper_secretary_messages
                            .reorder(created_at: :asc)
                            .limit(100)
  end

  def send_message
    begin
      Rails.logger.info("=== send_message START ===")
      Rails.logger.info("Params: #{params.inspect}")

      # 画像アップロード処理
      image_url = nil
      if params[:image].present?
        Rails.logger.info("Image upload START")
        uploaded_file = params[:image]
        filename = "#{SecureRandom.uuid}_#{uploaded_file.original_filename}"
        filepath = Rails.root.join('public', 'uploads', filename)
        FileUtils.mkdir_p(File.dirname(filepath))
        File.open(filepath, 'wb') do |file|
          file.write(uploaded_file.read)
        end
        image_url = "/uploads/#{filename}"
        Rails.logger.info("Image uploaded: #{image_url}")
      end

      # メッセージ内容の確認
      message_content = params[:message].presence || (image_url.present? ? "[画像]" : nil)
      
      if message_content.blank? && image_url.blank?
        Rails.logger.warn("Empty message and no image")
        redirect_to hub_secretary_path, alert: "メッセージまたは画像を入力してください"
        return
      end

      # ユーザーメッセージを保存
      Rails.logger.info("Creating user message: #{message_content}")
      user_message = current_user.hyper_secretary_messages.create!(
        content: message_content,
        role: 'user',
        image_url: image_url
      )
      Rails.logger.info("User message created: #{user_message.id}")

      # AI API呼び出し
      Rails.logger.info("Calling AI API")
      response = call_ai_api(message_content, params[:model] || 'claude-sonnet-4.5', image_url)
      Rails.logger.info("AI response: #{response[:message][0..100]}...")

      # AI返信を保存
      Rails.logger.info("Creating assistant message")
      assistant_message = current_user.hyper_secretary_messages.create!(
        content: response[:message],
        role: 'assistant',
        metadata: response[:metadata]
      )
      Rails.logger.info("Assistant message created: #{assistant_message.id}")

      # 秘書画面にリダイレクト
      Rails.logger.info("=== send_message SUCCESS ===")
      redirect_to hub_secretary_path, notice: "送信しました"
      
    rescue StandardError => e
      Rails.logger.error("=== send_message ERROR ===")
      Rails.logger.error("Error: #{e.message}")
      Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
      redirect_to hub_secretary_path, alert: "エラーが発生しました: #{e.message}"
    end
  end

  private

  def call_ai_api(message, model, image_url = nil)
    # メモリコンテキストを取得
    memory = HyperSecretaryMessage.get_memory_context(current_user, limit: 10)

    # システムコンテキスト（Chargeデータ）を取得
    system_context = build_system_context

    case model
    when 'gpt-4o'
      call_openai_api(message, memory, image_url)
    else
      call_anthropic_api(message, memory, image_url, system_context)
    end
  end

  def build_system_context
    # 最近のCharge記録を取得
    recent_charges = ChargeEntry.order(created_at: :desc).limit(20)

    # 集計
    total_in = ChargeEntry.where(direction: :incoming).sum(:amount_yen)
    total_out = ChargeEntry.where(direction: :outgoing).sum(:amount_yen)
    balance = total_in - total_out

    # 今日の記録
    today_charges = ChargeEntry.where(occurred_on: Date.current)
    today_in = today_charges.where(direction: :incoming).sum(:amount_yen)
    today_out = today_charges.where(direction: :outgoing).sum(:amount_yen)

    charge_list = recent_charges.map do |c|
      dir = c.direction_incoming? ? "受取" : "支払"
      "- #{c.occurred_on&.strftime('%m/%d') || '日付なし'} #{dir} ¥#{c.amount_yen.to_i} #{c.counterparty} #{c.category} #{c.note}"
    end.join("\n")

    <<~CONTEXT
      【HUB9システム情報】
      あなたはHUB9の秘書AIです。HUB9は個人のお金の出入り（Charge）を管理するアプリです。

      【現在の残高状況】
      - 総受取: ¥#{total_in.to_i.to_s(:delimited)}
      - 総支払: ¥#{total_out.to_i.to_s(:delimited)}
      - 差引残高: ¥#{balance.to_i.to_s(:delimited)}

      【今日の記録】
      - 受取: ¥#{today_in.to_i.to_s(:delimited)}
      - 支払: ¥#{today_out.to_i.to_s(:delimited)}

      【最近のCharge記録（最新20件）】
      #{charge_list.presence || "まだ記録がありません"}

      ユーザーからチャージや残高について聞かれたら、上記のデータを参照して回答してください。
    CONTEXT
  end

  def call_anthropic_api(message, memory, image_url = nil, system_context = nil)
    require 'net/http'
    require 'json'

    # メッセージコンテンツを構築
    content = []

    # 画像がある場合
    if image_url.present?
      image_path = Rails.root.join('public', image_url.gsub(/^\//, ''))
      if File.exist?(image_path)
        image_data = Base64.strict_encode64(File.read(image_path))

        content << {
          type: "image",
          source: {
            type: "base64",
            media_type: "image/jpeg",
            data: image_data
          }
        }
      end
    end

    # テキストメッセージ
    if message.present?
      content << {
        type: "text",
        text: message
      }
    end

    # システムプロンプト構築
    system_prompt = "あなたはHUB9の秘書AIです。丁寧かつ簡潔に回答してください。\n\n#{system_context}"

    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = ENV['ANTHROPIC_API_KEY']
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"

    request.body = {
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: system_prompt,
      messages: [
        *memory,
        { role: "user", content: content }
      ]
    }.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      text = data.dig('content', 0, 'text')
      { message: text, metadata: { model: 'claude-sonnet-4.5' } }
    else
      raise "API Error: #{response.code} - #{response.body}"
    end
  end

  def call_openai_api(message, memory, image_url = nil)
    # 簡易実装
    { message: "GPT-4o APIは未実装です", metadata: { model: 'gpt-4o' } }
  end
end
