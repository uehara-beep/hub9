module Hub9
  class HyperSecretary
    RECORD_HINTS = [
      "記録", "メモ", "保存", "残して", "控えて", "ログ", "登録", "アーカイブ"
    ].freeze

    def self.record_intent?(text)
      t = text.to_s.strip
      return false if t.empty?
      return false if t.match?(/(したらいい|どうする|どうしたら|おすすめ|何がいい|悩んでる|相談|教えて)\??/)
      RECORD_HINTS.any? { |k| t.include?(k) }
    end

    def self.system_prompt(mode_label: "Hyper秘書", allow_memory: true)
      <<~PROMPT
      あなたはHUB9の「#{mode_label}」です。ユーザー(Ta9)の相棒として、柔軟に判断し、具体策を出してください。

      絶対ルール:
      - 返答はテンプレ禁止。「OK。Aモードで記録した。」のような定型句は使わない。
      - ユーザーが"相談"している時は、結論→理由→具体案(2〜4個)→次の一手、の順で提案する。
      - ユーザーが"記録"を求めた時だけ、短く「記録内容の要約」と「次の確認点」を返す。
      - 不要な確認質問はしない。必要なら質問は最大1個まで。
      - 口調は落ち着いて、実務的、でも冷たくしない（上品で頼れる秘書）。
      - モバイル前提：短文、見出し、箇条書き中心。

      記録の扱い:
      - "記録した"と言ってよいのは、アプリ側でDB保存が成功した場合のみ（それ以外は言わない）。
      - 相談の回答を「記録した」扱いにしない。必要なら「この内容、メモとして残す？」と1行だけ提案。

      セキュリティ:
      - PINや秘密情報の取り扱いは慎重に。表示上は必要最小限。
      PROMPT
    end
  end
end
