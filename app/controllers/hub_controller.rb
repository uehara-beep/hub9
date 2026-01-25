class HubController < ApplicationController
  # メイン入口は「秘書」のみ。議事録/朝/夜は裏メニュー扱い
  MENUS = [
    { key: "secretary", label: "🤵 秘書", path: "/hub?mode=A" },
    { key: "vault", label: "💸 送金（裏）", path: "/vault" }
  ].freeze

  # 表示するモードは秘書のみ、他はURL直打ち可
  MODES = [
    { key: "A", label: "秘書" }
  ].freeze

  # 裏モード（URL直打ち用）
  HIDDEN_MODES = [
    { key: "B", label: "議事録" },
    { key: "C", label: "進捗" },
    { key: "D", label: "朝" },
    { key: "E", label: "夜" }
  ].freeze

  def index
    @menus = MENUS
    @modes = MODES

    if params[:mode].present?
      @mode = params[:mode]
      all_modes = MODES + HIDDEN_MODES
      mode_info = all_modes.find { |m| m[:key] == @mode }
      @modes = [mode_info].compact.presence || MODES

      session[:hub_mode] = @mode
      @conversation = Conversation.find_or_create_by!(mode: @mode)
      @messages = @conversation.messages.order(:id).last(50)
      render :chat
    else
      @vault_balance = calculate_vault_balance
      @today_entries = vault_today_entries
      @purge_warning_count = purge_warning_count
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

    # Use HyperSecretary AI if available
    begin
      ai = Hub9::AiChat.new(mode_label: mode_label_for(mode))
      history = conv.messages.order(:id).last(12).map { |m| { role: m.role, content: m.content } }
      is_record = Hub9::HyperSecretary.record_intent?(user_text)
      temperature = is_record ? 0.2 : 0.8
      assistant_text = ai.call(messages: history, temperature: temperature)
    rescue => e
      Rails.logger.error("[HubController] AI error: #{e.message}")
      assistant_text = "通信エラーが発生しました。もう一度お試しください。"
    end

    conv.messages.create!(role: "assistant", content: assistant_text)
    redirect_to hub_path(mode: mode)
  end

  private

  def mode_label_for(key)
    all = MODES + HIDDEN_MODES
    all.find { |m| m[:key] == key }&.fetch(:label, "秘書") || "秘書"
  end

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

  def purge_warning_count
    return 0 unless defined?(VaultEntry)
    # 30日以内に自動削除されるエントリ数
    VaultEntry.where("purge_on <= ?", 30.days.from_now).count
  rescue
    0
  end
end
