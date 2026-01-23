# config/puma.rb

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 3).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

environment ENV.fetch("RAILS_ENV", "production")

port = ENV.fetch("PORT", 8080).to_i
bind "tcp://0.0.0.0:#{port}"

workers ENV.fetch("WEB_CONCURRENCY", 1).to_i
preload_app!

plugin :tmp_restart
