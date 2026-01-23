class UserPreference < ApplicationRecord
  belongs_to :user, optional: true

  enum :strictness, { gentle: 0, normal: 1, strict: 2 }

  STRICTNESS_PROMPTS = {
    gentle: "優しく補足し、安心感を与える口調で。",
    normal: "簡潔で実務的に。",
    strict: "無駄を省き、甘えを許さず、判断を迫る。"
  }.freeze

  def strictness_prompt
    STRICTNESS_PROMPTS[strictness.to_sym] || STRICTNESS_PROMPTS[:normal]
  end
end
