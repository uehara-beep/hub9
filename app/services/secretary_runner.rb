class SecretaryRunner
  def self.run(command)
    controller = Api::ChatController.new

    fake_request = ActionDispatch::Request.new({})
    controller.request = fake_request

    controller.params = { message: command }
    result = controller.create

    # 通知を送信
    if result.is_a?(Hash) && result[:reply]
      SecretaryNotifier.slack(result[:reply])
    end

    result
  rescue => e
    Rails.logger.error("[SecretaryRunner] #{e.message}")
    nil
  end
end
