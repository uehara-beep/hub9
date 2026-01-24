# frozen_string_literal: true
class Vault::TransfersController < ApplicationController
  before_action :require_vault_unlocked!

  def new
    @kind = params[:kind].presence_in(%w[in out]) || "out"
  end

  def create
    kind        = params[:kind].presence_in(%w[in out]) || "out"
    amount      = params[:amount].to_s.gsub(/[^\d]/, "").to_i
    counterparty = params[:counterparty].to_s.strip
    category    = params[:category].to_s.strip
    subcategory = params[:subcategory].to_s.strip
    memo        = params[:memo].to_s.strip

    title_parts = []
    title_parts << (kind == "in" ? "貰い" : "支払い")
    title_parts << category if category.present?
    title_parts << subcategory if subcategory.present?
    title_parts << counterparty if counterparty.present?
    title = title_parts.join(" / ").presence || "送金"

    body_lines = []
    body_lines << "相手: #{counterparty}" if counterparty.present?
    body_lines << "カテゴリ: #{category}" if category.present?
    body_lines << "内訳: #{subcategory}" if subcategory.present?
    body_lines << memo if memo.present?
    body = body_lines.join("\n").presence

    entry = VaultEntry.new(
      kind: kind == "in" ? :income : :expense,
      amount_yen: amount,
      tag: title,
      memo: body,
      hidden: true,
      occurred_on: Date.today
    )

    if params[:receipt].present?
      entry.receipt.attach(params[:receipt])
      entry.ocr_status = "queued" if entry.respond_to?(:ocr_status=)
    end

    if entry.save
      begin
        VaultOcrJob.perform_later(entry.id) if defined?(VaultOcrJob) && entry.receipt.attached?
      rescue StandardError
        # no-op
      end
      redirect_to vault_entry_path(entry), notice: "送金を記録しました"
    else
      flash.now[:alert] = entry.errors.full_messages.join(", ")
      @kind = kind
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_vault_unlocked!
    unless session[:vault_unlocked]
      redirect_to "/vault", alert: "PINを入力してください"
    end
  end
end
