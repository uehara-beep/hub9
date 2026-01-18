# frozen_string_literal: true

# Railway build (assets:precompile) runs with SECRET_KEY_BASE_DUMMY=1
# In this phase, DB may not exist yet. Skip Devise initialization.
return if ENV["SECRET_KEY_BASE_DUMMY"] == "1"

Devise.setup do |config|
  # ==> Configuration for Devise
  # (keep default generated settings below)

  config.mailer_sender = "please-change-me@example.com"

  require "devise/orm/active_record"

  # You can keep the rest of the defaults Devise generated.
end
