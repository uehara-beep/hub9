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
