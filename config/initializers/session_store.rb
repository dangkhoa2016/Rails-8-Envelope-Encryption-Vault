Rails.application.config.session_store :cookie_store,
  key: "_ruby_envelope_vault_session",
  httponly: true,
  same_site: :strict,
  secure: Rails.env.production? && ENV.fetch("FORCE_SSL", "true") == "true",
  expire_after: Rails.application.config.x.security.session_absolute_timeout
