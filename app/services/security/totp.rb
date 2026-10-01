require "openssl"
require "securerandom"
require "uri"

module Security
  class Totp
    ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".freeze

    def self.generate_secret(bytes: 20)
      base32_encode(SecureRandom.random_bytes(bytes))
    end

    def self.code(secret:, at: Time.now, digits: 6, period: 30)
      counter = (at.to_i / period).floor
      digest = OpenSSL::HMAC.digest("SHA1", base32_decode(secret), [ counter ].pack("Q>"))
      offset = digest.getbyte(-1) & 0x0f
      binary = ((digest.getbyte(offset) & 0x7f) << 24) |
               (digest.getbyte(offset + 1) << 16) |
               (digest.getbyte(offset + 2) << 8) |
               digest.getbyte(offset + 3)
      (binary % (10**digits)).to_s.rjust(digits, "0")
    end

    def self.valid?(token:, secret:, at: Time.now, digits: 6, period: 30, drift_steps: 1)
      !matching_counter(token:, secret:, at:, digits:, period:, drift_steps:).nil?
    end

    def self.matching_counter(token:, secret:, at: Time.now, digits: 6, period: 30, drift_steps: 1)
      candidate = token.to_s.gsub(/\s+/, "")
      return nil unless candidate.match?(/\A\d{#{digits}}\z/)

      base_counter = (at.to_i / period).floor
      (-drift_steps..drift_steps).each do |step|
        counter = base_counter + step
        next if counter.negative?
        expected = code(secret: secret, at: Time.at(counter * period), digits: digits, period: period)
        return counter if OpenSSL.fixed_length_secure_compare(expected, candidate)
      end
      nil
    rescue ArgumentError
      nil
    end

    def self.provisioning_uri(secret:, email:, issuer: "Ruby Envelope Vault")
      label = URI.encode_www_form_component("#{issuer}:#{email}")
      query = URI.encode_www_form(secret: secret, issuer: issuer, algorithm: "SHA1", digits: 6, period: 30)
      "otpauth://totp/#{label}?#{query}"
    end

    def self.base32_encode(bytes)
      bits = bytes.bytes.map { |b| b.to_s(2).rjust(8, "0") }.join
      bits.scan(/.{1,5}/).map { |chunk| ALPHABET[chunk.ljust(5, "0").to_i(2)] }.join
    end

    def self.base32_decode(value)
      clean = value.to_s.upcase.delete("= \t\r\n-")
      raise ArgumentError, "invalid base32 secret" if clean.empty? || clean.match?(/[^A-Z2-7]/)
      bits = clean.chars.map { |char| ALPHABET.index(char).to_s(2).rjust(5, "0") }.join
      bits.scan(/.{8}/).map { |byte| byte.to_i(2) }.pack("C*")
    end

    private_class_method :base32_encode, :base32_decode
  end
end
