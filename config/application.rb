require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Duroosi
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
    
    # Configuring generators to use rspec and factory-girl
    config.generators do |g| 
      g.test_framework :rspec, 
        :fixtures => true, 
        :view_specs => false, 
        :helper_specs => false, 
        :routing_specs => false, 
        :controller_specs => true, 
        :request_specs => false 
      
      g.fixture_replacement :factory_girl, :dir => "spec/factories" 
    end
    
    # Initialize redis and load application configuration
    config_databases = {
      "development" => 10, 
      "test" => 11, 
      "production" => 12
    }

    $redis = Redis.new(db: config_databases[Rails.env.to_s])
    if $redis.exists('config.site')
      config.site = JSON.parse($redis.get('config.site'))
    else
      config.site = YAML.load_file("#{Rails.root}/config/config-site.yml")['site']
      $redis.set 'config.site', config.site.to_json
    end
    
    $site = config.site
    
    config.site_engines = {}
    
    config.time_zone = config.site['time_zone']
    config.i18n.default_locale = config.site['locale']
  end
end