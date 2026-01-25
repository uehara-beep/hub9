class ChargeEntriesController < ApplicationController
  def index
    @entries = ChargeEntry.order(created_at: :desc).limit(200)
  end

  def new
    @entry = ChargeEntry.new(occurred_on: Date.current)
  end

  def create
    @entry = ChargeEntry.new(entry_params)
    @entry.occurred_on ||= Date.current
    if @entry.save
      redirect_to charge_entries_path, notice: "記録しました"
    else
      flash.now[:alert] = "入力を確認してね"
      render :new, status: 422
    end
  end

  private

  def entry_params
    params.require(:charge_entry).permit(:direction, :amount_yen, :category, :counterparty, :note, :occurred_on)
  end
end
