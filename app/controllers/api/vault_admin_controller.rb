class Api::VaultAdminController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :require_vault_unlocked!

  # POST /api/vault/wipe_all
  def wipe_all
    count = 0
    VaultEntry.find_each do |e|
      e.receipt.purge if e.respond_to?(:receipt) && e.receipt.attached?
      e.destroy!
      count += 1
    end

    # 警告通知もクリア
    Notification.where(kind: "vault_purge_warning").delete_all if defined?(Notification)

    Rails.logger.info("[VaultAdmin] Wiped #{count} entries")

    respond_to do |format|
      format.html { redirect_to "/vault/home", notice: "#{count}件の送金記録を削除しました" }
      format.json { render json: { ok: true, deleted: count } }
    end
  end

  private

  def require_vault_unlocked!
    unless session[:vault_unlocked] == true
      respond_to do |format|
        format.html { redirect_to "/vault", alert: "PINを入力してください" }
        format.json { head :unauthorized }
      end
    end
  end
end
