require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module PlugNPlay
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Autoload services
    config.autoload_paths += %W(#{config.root}/app/services/concerns)
    config.autoload_paths += %W(#{config.root}/app/services)

    # Cache configuration
    #config.cache_store = :memory_store, { size: 128.megabytes }
    config.cache_store = :file_store, "#{config.root}/tmp/cache/rails"

    # Basic authentication
    config.pnp_user = "pnp"
    config.pnp_password = "password"
  end
end
