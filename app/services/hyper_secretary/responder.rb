module HyperSecretary
  class Responder
    def self.call(user_text:, parsed:)
      kind = parsed[:kind]

      system = <<~SYS
        あなたは「Ta9専用のハイパー秘書」です。
        口調はフレンドリーで短く、でも内容は具体的に。
        重要: 「覚えてない」などは言わない。必要情報が足りない場合は質問で埋める。
        ユーザーの手間を減らす提案を必ず1つ入れる。
      SYS

      context = case kind
      when "charge"
        <<~CTX
          ユーザーは送金/立替/支払いを記録したい。
          解析結果:
          - direction: #{parsed[:direction].inspect} (0=受取,1=支払)
          - amount_yen: #{parsed[:amount_yen].inspect}
          - category: #{parsed[:category].inspect}
          - counterparty: #{parsed[:counterparty].inspect}
          - note: #{parsed[:note].inspect}
          返答では「記録した内容」を1行で要約し、足りない項目があれば最小限だけ聞く。
        CTX
      when "vault"
        <<~CTX
          ユーザーは外に出せない記録（へそくり/裏メモ/領収書）を残したい。
          「安全に残す」「後で消す」前提で、次の一手を案内する。
        CTX
      else
        <<~CTX
          相談/段取り/意思決定として対応する。
          結論→理由→次の一手(最小) の順で。
        CTX
      end

      user = <<~USER
        [ユーザー文]
        #{user_text}

        [裏の分類/抽出]
        #{parsed}

        これに基づいて返答して。
      USER

      begin
        OpenAI.chat(system: system + "\n" + context, user: user, temperature: 0.4)
      rescue
        # fallback
        "了解。要点だけ確認するね：いま「#{parsed[:intent]}」。金額や相手が分かれば一発で整理できる。金額いくら？相手は誰？"
      end
    end
  end
end
