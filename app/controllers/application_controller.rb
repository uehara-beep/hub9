class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # ===== ta9 Login Guard =====
  before_action :require_ta9_login

  def require_ta9_login
    return if controller_name == "auth"
    return if request.path.start_with?("/api/")
    redirect_to login_path unless session[:ta9_logged_in]
  end
  # ===========================

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
