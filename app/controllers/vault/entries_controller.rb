class Vault::EntriesController < ApplicationController
  before_action :require_vault_unlocked
  before_action :set_entry, only: [:show, :destroy]

  def index
    @entries = VaultEntry.order(occurred_on: :desc, created_at: :desc).limit(300)
  end

  def new
    @entry = VaultEntry.new(occurred_on: Date.today, kind: :expense)
  end

  def create
    @entry = VaultEntry.new(entry_params)
    if @entry.save
      VaultOcrJob.perform_later(@entry.id) if @entry.receipt.attached?
      redirect_to vault_entry_path(@entry), notice: "保存しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @entry.destroy!
    redirect_to vault_entries_path, notice: "削除しました"
  end

  private

  def set_entry
    @entry = VaultEntry.find(params[:id])
  end

  def entry_params
    params.require(:vault_entry).permit(:occurred_on, :kind, :category, :amount_yen, :tag, :memo, :receipt)
  end
end
