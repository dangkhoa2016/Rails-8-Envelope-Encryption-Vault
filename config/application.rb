require_relative "boot"
require_relative "../lib/rate_limit_boundary"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module RubyEnvelopeVault
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.autoload_lib(ignore: %w[assets tasks])
    config.generators.system_tests = nil
    config.middleware.delete Rack::Attack
    config.middleware.insert_before ActionDispatch::Cookies, RateLimitBoundary
  end
end
