require "json"

module Hub9
  class Assistant
    def self.prefs
      @prefs ||= begin
        path = Rails.root.join("config/user_preference.json")
        JSON.parse(File.read(path))
      rescue
        {}
      end
    end

    def self.mode_system(mode)
      base = <<~SYS
        あなたはTa9専用の「秘書AI」です。
        口調は丁寧で簡潔。#{prefs["output_style"] || "結論→次→確認"}の順で出力。
        迷いが出たら、選択肢を3つに絞って提案し、最後に「次どうする？」を必ず聞く。
      SYS

      case mode
      when "minutes"
        base + "\n【議事録秘書モード】要点/決定事項/未決/ToDo(担当・期限)/次回議題 で整理。"
      when "progress"
        base + "\n【進捗管理秘書モード】タスクを分解し、優先度/期限/次アクションを提示。詰まってる原因も推測して1つだけ改善案。"
      when "morning"
        base + "\n【朝の秘書ブリーフ】" + (prefs["morning_brief"] || []).join(" / ")
      when "night"
        base + "\n【夜の秘書レビュー】" + (prefs["night_review"] || []).join(" / ")
      else
        base
      end
    end

    def self.apply_slash_command(text)
      t = (text || "").strip
      return { mode: nil, text: t } unless t.start_with?("/")

      cmd, rest = t.split(/\s+/, 2)
      rest ||= ""

      case cmd
      when "/整理して"
        {
          mode: nil,
          text: <<~TXT
            次の文章を「分類」「ToDo」「期限（不明は不明）」「依頼文案（必要なら）」「次の一手」で整理して。
            ----
            #{rest}
          TXT
        }
      when "/判断して"
        {
          mode: nil,
          text: <<~TXT
            次の内容について、選択肢を3つに絞って「メリデメ」「リスク」「推奨（理由）」で判断して。最後に次の一手を1つだけ提示して。
            ----
            #{rest}
          TXT
        }
      when "/議事録"
        { mode: "minutes", text: rest }
      when "/進捗"
        { mode: "progress", text: rest }
      when "/朝"
        { mode: "morning", text: rest.empty? ? "今日の朝ブリーフを作って。" : rest }
      when "/夜"
        { mode: "night", text: rest.empty? ? "今日の夜レビューを作って。" : rest }
      else
        { mode: nil, text: t }
      end
    end
  end
end
