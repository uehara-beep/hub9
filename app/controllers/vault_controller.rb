class VaultController < ApplicationController
  before_action :no_store
  before_action :require_vault_unlocked, except: [:index, :unlock]

  def index
  end

  def unlock
    pin = params[:pin].to_s
    if pin == ENV.fetch("VAULT_PIN", "")
      session[:vault_unlocked] = true
      redirect_to "/vault/home"
    else
      flash[:alert] = "PINが違います"
      redirect_to "/vault"
    end
  end

  def home
  end

  def money
    @entry = VaultEntry.new
  end

  def money_create
    @entry = VaultEntry.new(entry_params)

    case @entry.category
    when "charge"
      @entry.kind = :income
      @entry.hidden = false
    when "advance", "transfer"
      @entry.kind = :expense
      @entry.hidden = false
    when "hidden"
      @entry.kind = (@entry.kind.presence || :expense)
      @entry.hidden = true
    else
      @entry.kind = (@entry.kind.presence || :expense)
    end

    # Set required fields
    @entry.occurred_on ||= Date.today
    @entry.amount_yen = @entry.amount if @entry.respond_to?(:amount) && @entry.amount.present?

    if @entry.save
      redirect_to "/vault/home", notice: "記録しました"
    else
      render :money, status: :unprocessable_entity
    end
  end

  private

  def no_store
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
  end

  def require_vault_unlocked
    redirect_to "/vault" unless session[:vault_unlocked]
  end

  def entry_params
    params.require(:vault_entry).permit(:title, :amount, :amount_yen, :note, :memo, :category, :kind, :receipt, :hidden, :occurred_on, :tag)
  end
end
