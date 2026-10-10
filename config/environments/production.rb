require "active_support/core_ext/integer/time"
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.exceptions_app = ->(env) { Rails.application.routes.call(env) }
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
  config.assume_ssl = ENV.fetch("ASSUME_SSL", config.force_ssl.to_s) == "true"
  # Reject cross-site and opaque-origin state-changing requests in addition to
  # requiring Rails authenticity tokens.
  config.action_controller.forgery_protection_origin_check = true
  if config.force_ssl
    config.ssl_options = {
      redirect: { exclude: ->(request) { %w[/up /ready].include?(request.path) } },
      hsts: { expires: 1.year, subdomains: true, preload: false }
    }
  end

  hosts = (ENV["APP_HOSTS"].presence || ENV["APP_HOST"].presence).to_s.split(",").map(&:strip).reject(&:empty?)
  hosts.each { |host| config.hosts << host }
  config.host_authorization = { exclude: ->(request) { %w[/up /ready].include?(request.path) } }

  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.cache_store = :solid_cache_store
  config.active_record.attributes_for_inspect = [ :id ]

  config.action_dispatch.default_headers.merge!(
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "Referrer-Policy" => "same-origin",
    "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
    "Cross-Origin-Opener-Policy" => "same-origin",
    "Cross-Origin-Resource-Policy" => "same-origin",
    "X-Permitted-Cross-Domain-Policies" => "none"
  )
end
