# =============================================
# Charge: 直接入力で受取/支払を記録
# - フォームから手動入力（AI不要）
# - 受取(incoming) / 支払(outgoing)
# - Secretaryからも自動作成される
# =============================================
class ChargeEntriesController < ApplicationController
  def index
    @entries = ChargeEntry.order(occurred_on: :desc, created_at: :desc).limit(200)
    @entry = ChargeEntry.new(occurred_on: Date.current, direction: :incoming)
  end

  def create
    @entry = ChargeEntry.new(entry_params)
    @entry.occurred_on ||= Date.current

    if @entry.save
      redirect_to charge_entries_path, notice: "記録しました"
    else
      @entries = ChargeEntry.order(occurred_on: :desc, created_at: :desc).limit(200)
      flash.now[:alert] = @entry.errors.full_messages.join(" / ")
      render :index, status: :unprocessable_entity
    end
  end

  private

  def entry_params
    params.require(:charge_entry).permit(:direction, :amount_yen, :counterparty, :category, :note, :occurred_on)
  end
end
