class VaultController < ApplicationController
  before_action :no_store

  def index
  end

  def home
  end

  private

  def no_store
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
  end
end
