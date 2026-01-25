class Api::SecretaryController < ApplicationController
  skip_before_action :require_ta9_login
  protect_from_forgery with: :null_session

  def create
    content = params[:content].to_s.strip
    return render json: { error: "empty" }, status: 422 if content.empty?

    # 1) user message保存
    HyperSecretaryMessage.create!(
      role: "user",
      content: content
    )

    # 2) AIで分類 + 抽出
    result = HyperSecretary::Classifier.call(content)

    # 3) charge自動登録（kind == charge の時）
    charge_entry = nil
    if result[:kind] == "charge"
      charge_entry = ChargeEntry.create!(
        direction: result[:direction],             # 0: in, 1: out
        amount_yen: result[:amount_yen].to_i,
        category: result[:category].presence || "その他",
        counterparty: result[:counterparty].to_s,
        note: result[:note].to_s,
        occurred_on: Date.current
      )
    end

    # 4) assistant返信生成（分類結果を踏まえて"具体的に"返す）
    reply = HyperSecretary::Responder.call(user_text: content, parsed: result)

    # 5) assistant message保存（判定情報も一緒に持つ）
    HyperSecretaryMessage.create!(
      role: "assistant",
      content: reply,
      kind: result[:kind],
      direction: result[:direction],
      amount_yen: result[:amount_yen],
      category: result[:category],
      counterparty: result[:counterparty],
      extracted: result,
      charge_entry_id: charge_entry&.id
    )

    render json: {
      ok: true,
      kind: result[:kind],
      charge_entry_id: charge_entry&.id,
      reply: reply
    }
  end
end
