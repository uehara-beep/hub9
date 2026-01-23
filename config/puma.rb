# config/puma.rb

environment ENV.fetch("RAILS_ENV") { "production" }

# RailwayはPORTを渡す
port ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:#{ENV.fetch("PORT") { 3000 }}"

# ここが重要：DefaultRackup は使わない
rackup "config.ru"

threads 3, 3
workers 1
preload_app!
