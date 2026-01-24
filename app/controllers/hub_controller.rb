class HubController < ApplicationController
  MODES = [
    { key: "A", label: "秘書" },
    { key: "B", label: "議事録" },
    { key: "C", label: "進捗" },
    { key: "D", label: "朝" },
    { key: "E", label: "夜" }
  ].freeze

  def index
    @modes = MODES
    @mode = params[:mode].presence || session[:hub_mode].presence || "A"
    session[:hub_mode] = @mode

    @conversation = Conversation.find_or_create_by!(mode: @mode)
    @messages = @conversation.messages.order(:id).last(50)
  end

  def send_message
    mode = params[:mode].presence || session[:hub_mode].presence || "A"
    session[:hub_mode] = mode
    conv = Conversation.find_or_create_by!(mode: mode)

    user_text = params[:text].to_s.strip
    return redirect_to hub_path(mode: mode) if user_text.blank?

    conv.messages.create!(role: "user", content: user_text)

    # 直近履歴（OpenAIに渡す用）
    history = conv.messages.order(:id).last(20).map { |m| { role: m.role, content: m.content } }

    # --- ここは既存のAI呼び出しに置換してOK ---
    # 仮：とりあえず「記録してない」みたいな返しをやめるためのダミー
    assistant_text = "OK。#{mode}モードで記録した。続きも覚えてるよ。"

    conv.messages.create!(role: "assistant", content: assistant_text)

    redirect_to hub_path(mode: mode)
  end
end
