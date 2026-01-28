require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hub9
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Tokyo"
    # config.eager_load_paths << Rails.root.join("extras")

    # Railway build: skip migration errors during assets:precompile
    if ENV["ASSETS_PRECOMPILE"] || ENV["RAILS_ENV"] == "production"
      config.active_record.migration_error = false
      config.active_record.dump_schema_after_migration = false
    end
    if ENV["RAILS_ENV"] == "production"
      config.active_record.maintain_test_schema = false
    end
  end
end
