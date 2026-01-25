#!/bin/bash
set -e

echo "🔧 HUB9 秘書チャット表示問題を修正..."
echo ""

# ======================================
# 作業ディレクトリ確認
# ======================================
WORK_DIR="$HOME/Desktop/hub9"

if [ ! -d "$WORK_DIR" ]; then
  echo "❌ エラー: ~/Desktop/hub9 が見つかりません"
  exit 1
fi

cd "$WORK_DIR"
echo "✅ 作業ディレクトリ: $WORK_DIR"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  修正内容："
echo "  1. メッセージ表示順序の修正（.reverse削除）"
echo "  2. エラーハンドリング強化"
echo "  3. デバッグログ追加"
echo "  4. リダイレクト処理の改善"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ======================================
# 1. 秘書画面修正（.reverse削除）
# ======================================
echo "📝 1. 秘書画面修正（表示順序）..."

cat > app/views/hub/secretary.html.erb <<'ERB'
<div style="min-height: 100vh; background: #f6f1ea;">
  <!-- ヘッダー（固定） -->
  <div class="hub-header" style="background: #ff7a00; color: white; border-bottom: none;">
    <div class="hub-header-content">
      <div style="display: flex; align-items: center; gap: 12px;">
        <%= link_to "←", root_path, style: "color: white; font-size: 24px; text-decoration: none; font-weight: 700;" %>
        <div>
          <h1 style="color: white; margin: 0;">🤵 秘書</h1>
          <p style="font-size: 11px; color: rgba(255,255,255,.8); margin: 4px 0 0;">mode A</p>
        </div>
      </div>
    </div>
  </div>

  <!-- 会話エリア（スクロール可能） -->
  <div class="hub-content" id="chat-messages">
    <% if @messages.blank? %>
      <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
        <p style="font-size: 14px;">まだメッセージがありません</p>
        <p style="font-size: 12px; margin-top: 8px;">何でも話しかけてください</p>
      </div>
    <% else %>
      <div class="chat-container">
        <!-- 新しい順に表示（descでソート済みなので.reverseは不要） -->
        <% @messages.each do |message| %>
          <div class="chat-message <%= message.role == 'user' ? 'chat-message-user' : '' %>">
            <!-- アバター -->
            <div class="chat-avatar <%= message.role == 'assistant' ? 'chat-avatar-assistant' : '' %>">
              <%= message.role == 'user' ? 'ta9' : '秘書' %>
            </div>
            
            <!-- メッセージ内容 -->
            <div class="chat-message-content">
              <!-- 送信者名 -->
              <div class="chat-sender-name">
                <%= message.role == 'user' ? 'ta9' : '秘書' %>
              </div>
              
              <!-- 吹き出し -->
              <div class="chat-bubble <%= message.role == 'user' ? 'chat-bubble-user' : 'chat-bubble-assistant' %>">
                <%= simple_format(message.content) %>
                
                <!-- 画像がある場合 -->
                <% if message.image_url.present? %>
                  <img src="<%= message.image_url %>" class="chat-image" alt="添付画像">
                <% end %>
              </div>
              
              <!-- 時刻 -->
              <div class="chat-time">
                <%= message.created_at.strftime('%H:%M') %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>

  <!-- 入力エリア（固定） -->
  <div class="hub-footer-fixed">
    <div class="hub-footer-content">
      <%= form_with url: hub_send_message_path, 
                    method: :post,
                    multipart: true,
                    data: { 
                      controller: "line-chat",
                      action: "submit->line-chat#send"
                    } do |f| %>
        
        <!-- 画像プレビュー -->
        <div data-line-chat-target="previewContainer" style="display: none;" class="image-preview-container">
          <img data-line-chat-target="preview" class="image-preview" />
          <button type="button" 
                  class="image-preview-remove"
                  data-action="click->line-chat#removeImage">
            削除
          </button>
        </div>

        <!-- 入力ツールバー -->
        <div class="input-toolbar">
          <!-- ＋ボタン（画像添付） -->
          <label class="input-attach-btn">
            ＋
            <%= f.file_field :image,
                             accept: "image/*",
                             capture: "environment",
                             style: "display: none;",
                             data: { 
                               action: "change->line-chat#previewImage",
                               "line-chat-target": "fileInput"
                             } %>
          </label>

          <!-- 入力欄＋送信ボタン -->
          <div class="input-field-wrapper">
            <%= f.text_area :message, 
                            rows: 1,
                            placeholder: "メッセージを入力...",
                            data: { 
                              "line-chat-target": "input",
                              action: "keydown->line-chat#handleKeydown input->line-chat#autoResize"
                            } %>

            <button type="submit" 
                    class="input-send-btn"
                    data-line-chat-target="submit">
              ▶
            </button>
          </div>
        </div>

        <!-- モデル選択（小さく） -->
        <div style="margin-top: 8px; text-align: center;">
          <%= f.select :model, 
                       [["Sonnet 4.5", "claude-sonnet-4.5"], ["GPT-4o", "gpt-4o"]],
                       {},
                       style: "padding: 4px 8px; border-radius: 6px; border: 1px solid rgba(0,0,0,.15); font-size: 11px; background: white; color: #6b7280;" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
ERB

echo "✅ 秘書画面修正完了"

# ======================================
# 2. Hubコントローラー修正（リダイレクト）
# ======================================
echo "📝 2. Hubコントローラー修正（リダイレクト）..."

cat > app/controllers/hub_controller.rb <<'RUBY'
class HubController < ApplicationController
  before_action :authenticate_user!

  def index
    @purge_warning = current_user.vault_entries.deletion_notice.exists?
    @current_balance = current_user.vault_entries.this_month.calculate_balance
  end

  def secretary
    # 秘書画面（新しい順）
    @messages = current_user.hyper_secretary_messages
                            .order(created_at: :desc)
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
RUBY

echo "✅ Hubコントローラー修正完了"

# ======================================
# 3. モデル確認
# ======================================
echo "📝 3. モデル確認..."

cat > app/models/hyper_secretary_message.rb <<'RUBY'
class HyperSecretaryMessage < ApplicationRecord
  belongs_to :user

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }

  # 新しい順がデフォルト
  default_scope { order(created_at: :desc) }
  
  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :conversations, -> { where(role: %w[user assistant]) }

  # メモリコンテキスト取得（時系列順）
  def self.get_memory_context(user, limit: 10)
    unscoped  # default_scopeを一時的に無効化
      .where(user: user)
      .where(role: %w[user assistant])
      .order(created_at: :asc)  # 古い順
      .limit(limit)
      .map { |msg| { role: msg.role, content: msg.content } }
  end
end
RUBY

echo "✅ モデル確認完了"

# ======================================
# 4. Stimulusコントローラー簡素化
# ======================================
echo "📝 4. Stimulusコントローラー簡素化..."

cat > app/javascript/controllers/line_chat_controller.js <<'JS'
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "fileInput", "preview", "previewContainer"]

  connect() {
    console.log("LINE chat connected")
    this.scrollToBottom()
  }

  send(event) {
    // フォーム送信は通常通り（サーバーサイドでリダイレクト）
    const message = this.inputTarget.value.trim()
    const hasFile = this.fileInputTarget.files.length > 0
    
    if (!message && !hasFile) {
      event.preventDefault()
      alert("メッセージまたは画像を入力してください")
      return
    }
    
    this.submitTarget.disabled = true
    this.submitTarget.innerHTML = "⏳"
  }

  handleKeydown(event) {
    // Cmd/Ctrl + Enter で送信
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      const form = event.target.closest('form')
      form.requestSubmit()
    }
  }

  autoResize() {
    const textarea = this.inputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 100) + "px"
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewContainerTarget.style.display = "block"
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    this.fileInputTarget.value = ""
    this.previewContainerTarget.style.display = "none"
  }

  scrollToBottom() {
    setTimeout(() => {
      window.scrollTo(0, document.body.scrollHeight)
    }, 100)
  }
}
JS

echo "✅ Stimulusコントローラー簡素化完了"

# ======================================
# 5. Git操作
# ======================================
echo ""
echo "📦 Git操作..."

git add -A
git status -s

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  修正内容："
echo "  1. .reverse削除（表示順序修正）"
echo "  2. リダイレクト処理追加"
echo "  3. デバッグログ追加"
echo "  4. エラーハンドリング強化"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "変更をコミットしますか？ (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  git commit -m "fix: 秘書チャットの表示問題を修正

- .reverse削除（既にdescでソート済み）
- リダイレクト処理改善
- デバッグログ追加
- エラーハンドリング強化
- Stimulusコントローラー簡素化" || true
  
  git push
  
  echo "✅ Git push完了"
else
  echo "⚠️  コミットをスキップしました"
fi

# ======================================
# 完了
# ======================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎉 修正完了！"
echo ""
echo "  確認方法："
echo "  1. rails s でサーバー起動"
echo "  2. http://localhost:3000/hub を開く"
echo "  3. メッセージを送信してみる"
echo "  4. rails logs で詳細ログを確認"
echo ""
echo "  ログ確認："
echo "  tail -f log/development.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔥 メッセージが表示されるはずです！"
