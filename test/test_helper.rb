ENV["RAILS_ENV"] ||= "test"
ENV["VAULT_KEY_PROVIDER"] ||= "local_file"
ENV["VAULT_ACTIVE_KEK_ID"] ||= "kek-test-01"
ENV["VAULT_KEK_DIR"] ||= File.expand_path("../tmp/test-keks", __dir__)
require "fileutils"
require "openssl"
FileUtils.mkdir_p(ENV["VAULT_KEK_DIR"])
key_path = File.join(ENV["VAULT_KEK_DIR"], "#{ENV['VAULT_ACTIVE_KEK_ID']}.key")
File.binwrite(key_path, OpenSSL::Random.random_bytes(32)) unless File.exist?(key_path)
File.chmod(0o600, key_path)

require_relative "../config/environment"
require "rails/test_help"

# Functional tests should not spend production-strength CPU on BCrypt.
# Production cost settings are unchanged; this applies only in the test process.
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST if defined?(BCrypt::Engine)

class ActiveSupport::TestCase
  parallelize(workers: 1)
end

# Rack::Attack uses the shared Rails cache. Request specs that intentionally
# exhaust a throttle must not leak counters into unrelated integration tests.
# This clears counters at the start of each integration test while preserving
# normal accumulation across multiple requests inside the same test.
class ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
    Current.reset if defined?(Current)
  end

  teardown do
    Current.reset if defined?(Current)
  end
end
