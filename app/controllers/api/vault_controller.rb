class Api::VaultController < ApplicationController
  protect_from_forgery with: :null_session

  def unlock
    pin = params[:pin].to_s
    ok  = ActiveSupport::SecurityUtils.secure_compare(pin, (ENV["VAULT_PIN"] || ""))

    render json: { ok: ok }
  end
end
