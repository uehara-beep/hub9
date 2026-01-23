# frozen_string_literal: true

max_threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 3))
min_threads_count = max_threads_count
threads min_threads_count, max_threads_count

environment ENV.fetch("RAILS_ENV", "production")

# Railway が渡す PORT に 1回だけ bind
bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 3000)}"

workers Integer(ENV.fetch("WEB_CONCURRENCY", 1))
preload_app!

plugin :tmp_restart
