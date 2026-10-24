require "ipaddr"

module Audit
  # An explicit, minimal allowlist for investigating authentication actions.
  # No cookies, credentials, Authorization, body, query string or proxy headers.
  class RequestDetails
    AUTH_PATHS = %w[/session /mfa_challenge /reauthentication].freeze
    METHODS = %w[GET POST PUT PATCH DELETE].freeze

    def self.capture(request)
      agent = request.user_agent.to_s.gsub(/[[:cntrl:]]/, " ").strip.first(255)
      method = request.request_method.to_s
      path = request.path.to_s

      details = {}
      ip = valid_ip(request.remote_ip)
      details["ip_address"] = ip if ip
      details["user_agent"] = agent if agent.present?
      details["http_method"] = method if METHODS.include?(method)
      details["request_path"] = path if AUTH_PATHS.include?(path)
      details.freeze
    end

    def self.valid_ip(input)
      IPAddr.new(input.to_s).to_s
    rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
      nil
    end
    private_class_method :valid_ip
  end
end
