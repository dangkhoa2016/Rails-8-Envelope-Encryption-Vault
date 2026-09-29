require_relative "invalid_envelope_error"
require_relative "unsupported_envelope_version_error"

module Crypto
  class Envelope
    SUPPORTED_VERSION = 1
    CIPHER_SUITE = "AES-256-GCM"

    ATTRIBUTES = %i[
      envelope_version payload_format cipher_suite ciphertext nonce
      authentication_tag key_provider kek_id wrapped_dek aad_version
    ].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(**attributes)
      unknown = attributes.keys - ATTRIBUTES
      raise ArgumentError, "unknown envelope attributes: #{unknown.join(', ')}" if unknown.any?

      ATTRIBUTES.each { |name| instance_variable_set("@#{name}", attributes.fetch(name)) }
      validate!
      freeze
    end

    def to_h
      ATTRIBUTES.to_h { |name| [ name, public_send(name) ] }
    end

    private

    def validate!
      raise UnsupportedEnvelopeVersionError, "unsupported envelope version" unless envelope_version.to_i == SUPPORTED_VERSION
      raise InvalidEnvelopeError, "unsupported cipher suite" unless cipher_suite == CIPHER_SUITE
      raise InvalidEnvelopeError, "nonce must be 12 bytes" unless nonce&.bytesize == 12
      raise InvalidEnvelopeError, "authentication tag must be 16 bytes" unless authentication_tag&.bytesize == 16
      raise InvalidEnvelopeError, "ciphertext cannot be empty" if ciphertext.nil? || ciphertext.empty?
      raise InvalidEnvelopeError, "wrapped DEK cannot be empty" if wrapped_dek.nil? || wrapped_dek.empty?
      raise InvalidEnvelopeError, "key provider is required" if key_provider.to_s.empty?
      raise InvalidEnvelopeError, "KEK id is required" if kek_id.to_s.empty?
      raise InvalidEnvelopeError, "payload format is required" if payload_format.to_s.empty?
      raise InvalidEnvelopeError, "unsupported AAD version" unless aad_version.to_i == 1
    end
  end
end
