require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Olympus
  class Settings
    def admin_created!
      @admin_created = true
    end

    def admin_created?
      # NOTE: Memoizing false will not actually be enough here. False values
      # that are in ||= will be considered the same as nil
      unless @admin_created.nil?
        return @admin_created
      end

      @admin_created ||= Member.where(member_type: :application_admin).present?
    end

    def protocol
      central_config["protocol"]
    end

    def domain
      central_config["domain"]
    end

    def port
      central_config["port"]
    end

    def url
      base = "#{protocol}://#{domain}"
      [base, port].compact.join(":")
    end

    def auth_email_address
      central_config["auth_email_address"]
    end

    private

    def central_config
      @_central_config ||= YAML.load(
        File.read(
          Rails.root.join("config/central_config.yml")
        )
      )[Rails.env]
    end
  end

  @@settings ||= Settings.new

  def self.settings
    @@settings
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = :en

    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.precompile += %w( *.eot *.woff *.ttf *.otf *.svg )

    config.autoload_paths << Rails.root.join("app", "inputs")
    config.autoload_paths << Rails.root.join("app", "policies", "**", "*.rb")
    config.autoload_paths << Rails.root.join("app", "presenters", "**", "*.rb")

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.active_job.queue_adapter = :resque

    # https://github.com/sass/sassc-ruby/issues/167
    config.assets.configure do |env|
      env.export_concurrent = false
    end
  end
end
