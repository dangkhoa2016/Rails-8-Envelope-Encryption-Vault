module Crypto
  class AadBuilder
    APPLICATION = "ruby-envelope-vault"

    def self.call(envelope_version:, aad_version:, user_id:, vault_item_id:, vault_item_version_id:)
      raise ArgumentError, "unsupported AAD version" unless aad_version.to_i == 1

      [
        APPLICATION,
        "e=#{Integer(envelope_version)}",
        "a=#{Integer(aad_version)}",
        "u=#{required(user_id, :user_id)}",
        "i=#{required(vault_item_id, :vault_item_id)}",
        "v=#{required(vault_item_version_id, :vault_item_version_id)}"
      ].join("|")
    end

    def self.required(value, name)
      string = value.to_s
      raise ArgumentError, "#{name} is required" if string.empty? || string.include?("|")
      string
    end
    private_class_method :required
  end
end
