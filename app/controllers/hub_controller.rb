class HubController < ApplicationController
  MENUS = [
    { key: "secretary", label: "秘書", path: "/hub?mode=A" },
    { key: "vault", label: "Vault（裏）", path: "/vault" },
    { key: "minutes", label: "議事録", path: "/hub?mode=B" },
    { key: "progress", label: "進捗", path: "/hub?mode=C" }
  ].freeze

  MODES = [
    { key: "A", label: "秘書" },
    { key: "B", label: "議事録" },
    { key: "C", label: "進捗" },
    { key: "D", label: "朝" },
    { key: "E", label: "夜" }
  ].freeze

  def index
    @menus = MENUS
    @modes = MODES

    if params[:mode].present?
      # チャットモード
      @mode = params[:mode]
      session[:hub_mode] = @mode
      @conversation = Conversation.find_or_create_by!(mode: @mode)
      @messages = @conversation.messages.order(:id).last(50)
      render :chat
    else
      # ホーム画面
      @vault_balance = calculate_vault_balance
      @today_entries = vault_today_entries
      render :home
    end
  end

  def send_message
    mode = params[:mode].presence || session[:hub_mode].presence || "A"
    session[:hub_mode] = mode
    conv = Conversation.find_or_create_by!(mode: mode)

    user_text = params[:text].to_s.strip
    return redirect_to hub_path(mode: mode) if user_text.blank?

    conv.messages.create!(role: "user", content: user_text)

    history = conv.messages.order(:id).last(20).map { |m| { role: m.role, content: m.content } }

    assistant_text = "OK。#{mode}モードで記録した。続きも覚えてるよ。"
    conv.messages.create!(role: "assistant", content: assistant_text)

    redirect_to hub_path(mode: mode)
  end

  private

  def calculate_vault_balance
    return 0 unless defined?(VaultEntry)

    month_start = Date.today.beginning_of_month
    month_end = Date.today.end_of_month

    entries = VaultEntry.where(occurred_on: month_start..month_end)
    income = entries.where(kind: :income).sum(:amount_yen)
    expense = entries.where(kind: :expense).sum(:amount_yen)
    income - expense
  end

  def vault_today_entries
    return [] unless defined?(VaultEntry)
    VaultEntry.where(occurred_on: Date.today).order(created_at: :desc).limit(5)
  end
end
