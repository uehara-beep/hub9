rackup DefaultRackup
environment ENV.fetch("RAILS_ENV") { "production" }

port ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:#{ENV.fetch("PORT") { 3000 }}"

threads 3, 3
workers 1

preload_app!
