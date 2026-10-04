require "json"

module Crypto
  class PayloadSerializer
    MAX_BYTES = 1 * 1024 * 1024

    def self.dump(payload)
      raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)
      json = JSON.generate(payload)
      raise ArgumentError, "payload exceeds #{MAX_BYTES} bytes" if json.bytesize > MAX_BYTES
      json.encode(Encoding::UTF_8)
    end

    def self.load(json)
      raise ArgumentError, "payload exceeds #{MAX_BYTES} bytes" if json.bytesize > MAX_BYTES
      json = String(json).dup.force_encoding(Encoding::UTF_8)
      raise ArgumentError, "payload is not valid UTF-8" unless json.valid_encoding?
      value = JSON.parse(json)
      raise ArgumentError, "payload JSON must be an object" unless value.is_a?(Hash)
      value
    rescue JSON::ParserError => e
      raise ArgumentError, "invalid payload JSON"
    end
  end
end
