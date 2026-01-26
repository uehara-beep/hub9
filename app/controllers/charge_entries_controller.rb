# =============================================
# Charge: 直接入力で受取/支払を記録
# - フォームから手動入力（AI不要）
# - 受取(incoming) / 支払(outgoing)
# - Secretaryからも自動作成される
# - レシート読み取り機能（Claude Vision）
# =============================================
class ChargeEntriesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:scan_receipt]

  def index
    @entries = ChargeEntry.order(occurred_on: :desc, created_at: :desc).limit(200)
    @entry = ChargeEntry.new(occurred_on: Date.current, direction: :incoming)
  end

  def new
    @entry = ChargeEntry.new(occurred_on: Date.current, direction: :incoming)
  end

  def create
    @entry = ChargeEntry.new(entry_params)
    @entry.occurred_on ||= Date.current

    if @entry.save
      redirect_to charge_entries_path, notice: "記録しました"
    else
      @entries = ChargeEntry.order(occurred_on: :desc, created_at: :desc).limit(200)
      flash.now[:alert] = @entry.errors.full_messages.join(" / ")
      render :index, status: :unprocessable_entity
    end
  end

  def scan_receipt
    image_base64 = params[:image]

    unless image_base64.present?
      render json: { success: false, error: "画像がありません" }
      return
    end

    begin
      result = parse_receipt_with_claude(image_base64)
      render json: result.merge(success: true)
    rescue => e
      Rails.logger.error("Receipt scan error: #{e.message}")
      render json: { success: false, error: e.message }
    end
  end

  private

  def entry_params
    params.require(:charge_entry).permit(:direction, :amount_yen, :counterparty, :category, :note, :occurred_on)
  end

  def parse_receipt_with_claude(image_base64)
    require 'net/http'
    require 'json'

    api_key = ENV['ANTHROPIC_API_KEY']
    raise "ANTHROPIC_API_KEY not set" unless api_key.present?

    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"

    request.body = {
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image_base64
              }
            },
            {
              type: "text",
              text: <<~PROMPT
                このレシート画像を解析して、以下の情報をJSON形式で返してください。
                - amount: 合計金額（数字のみ、円記号やカンマなし）
                - store: 店名
                - category: カテゴリ（"交通費", "飲食", "立替", "雑", "その他" のいずれか）
                - note: 主な商品名（複数あれば最初の2-3個）

                JSONのみを返してください。説明は不要です。
                例: {"amount": 1280, "store": "セブンイレブン", "category": "飲食", "note": "おにぎり、お茶"}
              PROMPT
            }
          ]
        }
      ]
    }.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      content = data.dig('content', 0, 'text').to_s
      # JSONを抽出（```json ... ``` で囲まれている場合も対応）
      json_match = content.match(/\{[^}]+\}/m)
      if json_match
        JSON.parse(json_match[0])
      else
        { error: "レシートを読み取れませんでした" }
      end
    else
      raise "Claude API error: #{response.code}"
    end
  end
end
