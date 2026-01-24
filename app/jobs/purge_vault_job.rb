class PurgeVaultJob < ApplicationJob
  queue_as :default

  # 1日1回想定:
  # - purge_on <= today -> 物理削除（添付もpurge）
  # - purge_on == today+30 かつ purge_warned_at nil -> 通知作成
  def perform
    today = Date.current

    # 30日前通知
    warn_target = today + 30
    VaultEntry.where(purge_on: warn_target, purge_warned_at: nil).find_each do |e|
      Notification.create!(
        kind: "vault_purge_warning",
        title: "Vaultの自動削除が近いです",
        body: "「#{e.memo.presence || "記録"}」は #{e.purge_on} に自動削除されます。必要ならエクスポート/延長/削除を行ってください。"
      )
      e.update!(purge_warned_at: Time.current)
    end

    # 期限到達 -> 削除
    VaultEntry.where("purge_on <= ?", today).find_each do |e|
      e.receipt.purge if e.respond_to?(:receipt) && e.receipt.attached?
      e.destroy!
    end
  end
end
