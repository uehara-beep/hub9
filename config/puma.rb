port ENV.fetch("PORT", 8080)
bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 8080)}"
environment ENV.fetch("RAILS_ENV", "production")
plugin :tmp_restart
