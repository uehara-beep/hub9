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

    case model
    when 'gpt-4o'
      call_openai_api(message, memory, image_url)
    else
      call_anthropic_api(message, memory, image_url)
    end
  end

  def call_anthropic_api(message, memory, image_url = nil)
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

    api_response = HTTParty.post(
      "https://api.anthropic.com/v1/messages",
      headers: {
        "x-api-key" => ENV['ANTHROPIC_API_KEY'],
        "anthropic-version" => "2023-06-01",
        "content-type" => "application/json"
      },
      body: {
        model: "claude-sonnet-4-20250514",
        max_tokens: 1024,
        system: "あなたは有能な秘書です。ユーザーの指示を記憶し、適切に対応してください。",
        messages: [
          *memory,
          { role: "user", content: content }
        ]
      }.to_json,
      timeout: 30
    )

    if api_response.success?
      content = api_response['content'][0]['text']
      { message: content, metadata: { model: 'claude-sonnet-4.5' } }
    else
      raise "API Error: #{api_response.code} - #{api_response.body}"
    end
  end

  def call_openai_api(message, memory, image_url = nil)
    # 簡易実装
    { message: "GPT-4o APIは未実装です", metadata: { model: 'gpt-4o' } }
  end
end
