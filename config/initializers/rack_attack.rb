require "digest"
require "json"

Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  SESSION_COOKIE_NAME = "_ruby_envelope_vault_session"

  def self.normalized_login_email(req)
    # Rack's parameter parser is the canonical source for form/query parameters
    # and avoids hand-reading rack.input in throttling middleware. Keep a small
    # JSON fallback for API-style requests.
    email = req.params["email_address"]

    if email.blank? && req.media_type == "application/json"
      body = req.body.read(4096).to_s
      req.body.rewind
      email = JSON.parse(body)["email_address"]
    end

    email.to_s.strip.downcase.presence
  rescue JSON::ParserError, Rack::QueryParser::InvalidParameterError, ArgumentError
    nil
  ensure
    req.body.rewind rescue nil
  end

  # Hash the opaque Rails session cookie before using it as a throttle key.
  # The raw cookie value never appears in the cache key or logs.
  def self.session_fingerprint(req)
    raw = req.cookies[SESSION_COOKIE_NAME].to_s
    Digest::SHA256.hexdigest(raw) if raw.present?
  end

  safelist("health checks") { |req| %w[/up /ready].include?(req.path) }

  throttle("requests/ip", limit: 300, period: 60.seconds) do |req|
    req.ip unless %w[/up /ready].include?(req.path)
  end

  throttle("login/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  throttle("login/account", limit: 10, period: 10.minutes) do |req|
    if req.path == "/session" && req.post?
      email = normalized_login_email(req)
      Digest::SHA256.hexdigest(email) if email
    end
  end

  throttle("registration/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/registration" && req.post?
  end

  throttle("mfa/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/mfa_challenge" && req.post?
  end

  throttle("mfa/session", limit: 8, period: 5.minutes) do |req|
    session_fingerprint(req) if req.path == "/mfa_challenge" && req.post?
  end

  throttle("reauth/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/reauthentication" && req.post?
  end

  throttle("reauth/session", limit: 8, period: 5.minutes) do |req|
    session_fingerprint(req) if req.path == "/reauthentication" && req.post?
  end

  throttle("reveal/ip", limit: 120, period: 1.minute) do |req|
    req.ip if req.path.match?(%r{\A/vault_items/[^/]+/reveal\z}) && req.post?
  end

  throttle("reveal/session", limit: 60, period: 1.minute) do |req|
    session_fingerprint(req) if req.path.match?(%r{\A/vault_items/[^/]+/reveal\z}) && req.post?
  end

  throttle("export/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.path.match?(%r{\A/vault_items/[^/]+/export\z}) && req.post?
  end

  throttle("export/session", limit: 10, period: 1.hour) do |req|
    session_fingerprint(req) if req.path.match?(%r{\A/vault_items/[^/]+/export\z}) && req.post?
  end

  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period].to_i
    [
      429,
      {
        "Content-Type" => "text/plain; charset=utf-8",
        "Retry-After" => retry_after.to_s,
        "Cache-Control" => "no-store"
      },
      [ "Too many requests. Try again later." ]
    ]
  end
end
