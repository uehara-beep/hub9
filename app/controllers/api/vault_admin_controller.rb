class Api::VaultAdminController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :require_vault_unlocked!

  # POST /api/vault/wipe_all
  def wipe_all
    VaultEntry.find_each do |e|
      e.receipt.purge if e.respond_to?(:receipt) && e.receipt.attached?
      e.destroy!
    end

    Notification.where(kind: ["vault_purge_warning"]).delete_all

    render json: { ok: true }
  end

  private

  def require_vault_unlocked!
    head :unauthorized unless session[:vault_unlocked] == true
  end
end
