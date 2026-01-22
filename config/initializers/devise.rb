# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "please-change-me@example.com"

  require "devise/orm/active_record"
end
