class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # ===== Vault Guard =====
  def require_vault_unlocked
    return if session[:vault_unlocked] == true
    redirect_to "/vault", alert: "Vaultがロック中です"
  end

  def vault_unlock!
    session[:vault_unlocked] = true
  end

  def vault_lock!
    reset_session
  end
  # =======================
end
