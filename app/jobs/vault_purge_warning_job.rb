# frozen_string_literal: true
#
# 30日以内に自動削除される送金記録の警告通知を作成するジョブ
# 毎日cronで実行: VaultPurgeWarningJob.perform_later
#
class VaultPurgeWarningJob < ApplicationJob
  queue_as :default

  def perform
    # 30日以内に自動削除されるエントリを検索
    entries_to_warn = VaultEntry
      .where("purge_on <= ?", 30.days.from_now)
      .where("purge_on > ?", Date.today)
      .where(purge_warned_at: nil)

    return if entries_to_warn.empty?

    # 通知を作成
    if defined?(Notification)
      Notification.create!(
        kind: "vault_purge_warning",
        title: "送金記録の自動削除警告",
        body: "#{entries_to_warn.count}件の送金記録が30日以内に自動削除されます。確認してください。",
        read_at: nil
      )
    end

    # 警告済みフラグを立てる
    entries_to_warn.update_all(purge_warned_at: Time.current)

    Rails.logger.info("[VaultPurgeWarningJob] Warned #{entries_to_warn.count} entries")
  end
end
