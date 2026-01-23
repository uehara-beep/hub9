class Api::ChatController < ApplicationController
  skip_before_action :verify_authenticity_token

  SYSTEM_PROMPT = <<~PROMPT
    あなたはHUB9。
    ta9（ユーザー）専属の実務秘書AI。

    【役割】
    ・情報を「整理」し、「判断材料」を提示し、「次の一手」を決めやすくする
    ・結論ファースト、無駄な説明は省く
    ・経営／DX／建設業の文脈を前提として話す

    【基本姿勢】
    ・日本語で、簡潔・実務的
    ・友達ではなく「有能な秘書」
    ・感情に寄らず、事実と選択肢を出す
    ・最終判断は必ずta9に委ねる

    【出力ルール】
    常に以下の構造で返す：

    ■ 要点整理（事実・前提）
    ■ 判断ポイント（迷う所）
    ■ 選択肢（最大3つ）
    ■ おすすめ（理由つき・1つ）

    【禁止】
    ・長文の一般論
    ・抽象論だけの回答
    ・「人によります」「ケースバイケース」
  PROMPT

  def create
    user_message = Message.create!(
      content: params[:message],
      role: "user"
    )

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    command =
      if params[:message].start_with?("/整理して")
        :organize
      elsif params[:message].start_with?("/判断して")
        :decide
      elsif params[:message].start_with?("/議事録")
        :minutes
      elsif params[:message].start_with?("/進捗")
        :progress
      elsif params[:message].start_with?("/朝")
        :morning
      else
        :normal
      end

    system_extra =
      case command
      when :organize
        "入力内容を秘書として整理せよ。感情は除外し、事実と未確定を分ける。"
      when :decide
        "意思決定支援モード。選択肢は最大3つ。必ずおすすめを示せ。"
      when :minutes
        <<~MODE
          議事録秘書モード。入力内容から議事録を作成せよ。
          フォーマット：
          ■ 日時・場所・参加者
          ■ 議題
          ■ 決定事項
          ■ 未決事項・宿題（担当・期限）
          ■ 次回予定
        MODE
      when :progress
        <<~MODE
          進捗管理秘書モード。入力内容から進捗状況を整理せよ。
          フォーマット：
          ■ 全体進捗（%）
          ■ 完了項目
          ■ 進行中項目（残課題）
          ■ 遅延・リスク項目
          ■ 次のアクション（担当・期限）
        MODE
      when :morning
        "あなたはta9専属の朝の秘書。今日の行動を最小限に整理せよ。"
      else
        ""
      end

    history = Message.order(:created_at).last(10).map do |m|
      { role: m.role, content: m.content }
    end

    messages = [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "system", content: system_extra }
    ] + history

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages
      }
    )

    reply_text = response.dig("choices", 0, "message", "content")

    Message.create!(
      content: reply_text,
      role: "assistant"
    )

    render json: { reply: reply_text }
  end
end
