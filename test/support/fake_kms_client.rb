require "openssl"

module TestSupport
  class FakeKmsClient
    def initialize(keys:)
      @keys = keys.transform_keys(&:to_s)
    end

    def key_available?(key_id:)
      @keys.key?(key_id.to_s)
    end

    def encrypt(key_id:, plaintext:, encryption_context:)
      key = fetch_key(key_id)
      nonce = OpenSSL::Random.random_bytes(12)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.auth_data = context_aad(encryption_context)
      ciphertext = cipher.update(plaintext) + cipher.final

      nonce + cipher.auth_tag(16) + ciphertext
    end

    def decrypt(key_id:, ciphertext:, encryption_context:)
      key = fetch_key(key_id)
      blob = String(ciphertext).b
      raise "invalid fake KMS blob" if blob.bytesize < 28

      nonce = blob.byteslice(0, 12)
      tag = blob.byteslice(12, 16)
      payload = blob.byteslice(28..)

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.auth_tag = tag
      cipher.auth_data = context_aad(encryption_context)
      cipher.update(payload) + cipher.final
    end

    private

    def fetch_key(key_id)
      @keys.fetch(key_id.to_s)
    end

    def context_aad(context)
      context.sort.map { |key, value| "#{key}=#{value}" }.join("|")
    end
  end
end
