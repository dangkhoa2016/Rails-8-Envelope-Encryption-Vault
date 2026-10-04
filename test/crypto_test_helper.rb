require "minitest/autorun"
require "tmpdir"
require "securerandom"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "app/services"))

require File.join(ROOT, "app/services/crypto/error")
require File.join(ROOT, "app/services/crypto/invalid_envelope_error")
require File.join(ROOT, "app/services/crypto/authentication_error")
require File.join(ROOT, "app/services/crypto/unknown_key_provider_error")
require File.join(ROOT, "app/services/crypto/unknown_key_error")
require File.join(ROOT, "app/services/crypto/key_wrap_error")
require File.join(ROOT, "app/services/crypto/key_unwrap_error")
require File.join(ROOT, "app/services/crypto/unsupported_envelope_version_error")
require File.join(ROOT, "app/services/crypto/aad_builder")
require File.join(ROOT, "app/services/crypto/envelope")
require File.join(ROOT, "app/services/crypto/payload_serializer")
require File.join(ROOT, "app/services/key_providers/base")
require File.join(ROOT, "app/services/key_providers/local_file")
require File.join(ROOT, "app/services/crypto/envelope_encryptor")

module CryptoTestSupport
  def with_provider
    Dir.mktmpdir("revault-test") do |dir|
      File.binwrite(File.join(dir, "kek-test-01.key"), OpenSSL::Random.random_bytes(32))
      File.chmod(0o600, File.join(dir, "kek-test-01.key"))
      yield KeyProviders::LocalFile.new(key_dir: dir, active_key_id: "kek-test-01")
    end
  end

  def context
    @context ||= {
      user_id: SecureRandom.uuid,
      vault_item_id: SecureRandom.uuid,
      vault_item_version_id: SecureRandom.uuid
    }
  end
end
