class HyperSecretaryMessage < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :charge_entry, optional: true

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }

  enum :direction, { in: 0, out: 1 }, prefix: true

  # 新しい順がデフォルト
  default_scope { order(created_at: :desc) }

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :conversations, -> { where(role: %w[user assistant]) }

  # メモリコンテキスト取得（最新N件を時系列順で返す）
  def self.get_memory_context(user = nil, limit: 10)
    query = unscoped
    query = query.where(user: user) if user
    # 最新N件を取得してから時系列順に並べ替え
    recent = query.where(role: %w[user assistant])
      .order(created_at: :desc)
      .limit(limit)
      .to_a
      .reverse  # 古い→新しい順に
    recent.map { |msg| { role: msg.role, content: msg.content } }
  end
end
