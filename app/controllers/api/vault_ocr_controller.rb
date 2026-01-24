class Api::VaultOcrController < ApplicationController
  before_action :require_vault_unlocked

  def create
    entry = VaultEntry.find(params[:id])
    entry.update!(ocr_status: "queued", ocr_error: nil)
    VaultOcrJob.perform_later(entry.id)
    redirect_back fallback_location: vault_entries_path
  end
end
