module SecurityConfiguration
  module_function

  def integer(name, default, range:)
    value = Integer(ENV.fetch(name, default.to_s), 10)
    raise "#{name} must be within #{range}" unless range.cover?(value)
    value
  rescue ArgumentError
    raise "#{name} must be an integer within #{range}"
  end
end

idle_minutes = SecurityConfiguration.integer("SESSION_IDLE_TIMEOUT_MINUTES", 20, range: 5..1_440)
absolute_hours = SecurityConfiguration.integer("SESSION_ABSOLUTE_TIMEOUT_HOURS", 12, range: 1..168)
touch_seconds = SecurityConfiguration.integer("SESSION_TOUCH_INTERVAL_SECONDS", 60, range: 15..600)
reauth_minutes = SecurityConfiguration.integer("REAUTH_WINDOW_MINUTES", 5, range: 1..60)
pending_mfa_minutes = SecurityConfiguration.integer("PENDING_MFA_TIMEOUT_MINUTES", 5, range: 1..30)

Rails.application.config.x.security.session_idle_timeout = idle_minutes.minutes
Rails.application.config.x.security.session_absolute_timeout = absolute_hours.hours
Rails.application.config.x.security.session_touch_interval = touch_seconds.seconds
Rails.application.config.x.security.reauthentication_window = reauth_minutes.minutes
Rails.application.config.x.security.pending_mfa_timeout = pending_mfa_minutes.minutes
Rails.application.config.x.security.require_mfa = ENV.fetch("REQUIRE_MFA", Rails.env.production? ? "true" : "false") == "true"
Rails.application.config.x.security.reauth_on_reveal = ENV.fetch("REAUTH_ON_REVEAL", "true") == "true"
