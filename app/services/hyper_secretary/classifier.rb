require "json"

module HyperSecretary
  class Classifier
    # kind:
    # - consult 相談/意思決定/段取り
    # - charge 送金/チャージ/立替/返済/支払い
    # - vault  外に出せない記録（へそくり/裏金/領収書系）
    #
    # direction: 0=in(受取) 1=out(支払)
    def self.call(text)
      system = <<~SYS
        あなたは「Ta9専用のハイパー秘書」です。
        次のユーザー文を、必ずJSONだけで返してください。余計な文章は禁止。
        目的：会話を裏で分類し、必要なら送金・立替の記録に必要な項目を抽出する。

        出力JSONスキーマ:
        {
          "kind": "consult|charge|vault",
          "direction": 0 or 1 or null,
          "amount_yen": integer or null,
          "category": "交通費|飲食|立替|雑|その他" or null,
          "counterparty": string or null,
          "note": string or null,
          "intent": string (短い要約)
        }

        判定ルール:
        - 金銭の移動/立替/送金/返済/支払い/チャージ → kind="charge"
        - 外に出せないお金/へそくり/裏メモ/領収書台帳 → kind="vault"
        - それ以外（相談/段取り/意思決定/計画/質問）→ kind="consult"
        - amount_yen は「1万」「10,000」「5千」等を円の整数に正規化（不明ならnull）
        - direction は「受取/入金/もらい」=0、「支払/出金/払った/立替」=1、不明ならnull
      SYS

      begin
        raw = OpenAI.chat(system: system, user: text, temperature: 0.1)
        json = JSON.parse(raw) rescue nil
        return fallback(text) unless json.is_a?(Hash)

        # 正規化
        kind = json["kind"].to_s
        kind = "consult" unless %w[consult charge vault].include?(kind)

        {
          kind: kind,
          direction: json["direction"].nil? ? nil : json["direction"].to_i,
          amount_yen: json["amount_yen"].nil? ? nil : json["amount_yen"].to_i,
          category: json["category"],
          counterparty: json["counterparty"],
          note: json["note"],
          intent: json["intent"]
        }
      rescue
        fallback(text)
      end
    end

    def self.fallback(text)
      # OpenAI落ちた時も動くように最低限
      {
        kind: (text.include?("送金") || text.include?("立替") || text.include?("支払") || text.include?("チャージ")) ? "charge" : "consult",
        direction: nil,
        amount_yen: nil,
        category: nil,
        counterparty: nil,
        note: text,
        intent: "要確認"
      }
    end
  end
end
