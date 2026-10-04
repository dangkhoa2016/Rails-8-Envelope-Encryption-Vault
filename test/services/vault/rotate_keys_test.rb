require "test_helper"
require "openssl"
require_relative "../../support/in_memory_key_provider"
require_relative "../../../app/services/key_providers/external_kms"
require_relative "../../support/fake_kms_client"

class RotateKeysTest < ActiveSupport::TestCase
  test "dry run verifies rewrap without changing database" do
    user = User.create!(email_address: "rotate-dry@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    item = Vault::CreateItem.call(user: user, kind: "login", payload: { "schema" => "vault.login.v1", "title" => "rotation", "password" => "secret" })
    version = item.current_version
    old_wrapped = version.wrapped_dek.dup
    old_id = version.kek_id
    new_id = "kek-test-dry-02"
    create_key(new_id)

    previous_active = Rails.configuration.x.vault.active_kek_id
    Rails.configuration.x.vault.active_kek_id = new_id
    result = Vault::RotateKeys.call(from: old_id, to: new_id, dry_run: true)
    version.reload

    assert_operator result.scanned, :>=, 1
    assert_operator result.verified, :>=, 1
    assert_equal 0, result.rotated
    assert_equal old_wrapped, version.wrapped_dek
    assert_equal old_id, version.kek_id
  ensure
    Rails.configuration.x.vault.active_kek_id = previous_active if defined?(previous_active) && previous_active
  end

  test "rewrap changes wrapped DEK and preserves data ciphertext" do
    user = User.create!(email_address: "rotate@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    item = Vault::CreateItem.call(user: user, kind: "login", payload: { "schema" => "vault.login.v1", "title" => "rotation", "password" => "secret" })
    version = item.current_version
    old_ciphertext = version.ciphertext.dup
    old_wrapped = version.wrapped_dek.dup
    old_id = version.kek_id

    new_id = "kek-test-02"
    create_key(new_id)

    previous_active = Rails.configuration.x.vault.active_kek_id
    Rails.configuration.x.vault.active_kek_id = new_id
    result = Vault::RotateKeys.call(from: old_id, to: new_id)
    version.reload
    assert_operator result.rotated, :>=, 1
    assert_equal old_ciphertext, version.ciphertext
    refute_equal old_wrapped, version.wrapped_dek
    assert_equal new_id, version.kek_id

    provider = KeyProviders::LocalFile.new(key_dir: ENV.fetch("VAULT_KEK_DIR"), active_key_id: new_id)
    payload = Vault::RevealItem.call(user: user, item: item.reload, key_provider: provider, audit: false)
    assert_equal "rotation", payload["title"]
  ensure
    Rails.configuration.x.vault.active_kek_id = previous_active if defined?(previous_active) && previous_active
  end

  test "rotation works through registry with a non-local-file provider" do
    old_id = "memory-old"
    new_id = "memory-new"
    provider = TestSupport::InMemoryKeyProvider.new(
      keys: {
        old_id => OpenSSL::Random.random_bytes(32),
        new_id => OpenSSL::Random.random_bytes(32)
      },
      active_key_id: old_id
    )
    user = User.create!(
      email_address: "rotate-memory@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
    item = Vault::CreateItem.call(
      user: user,
      kind: "login",
      payload: { "schema" => "vault.login.v1", "title" => "memory rotation", "password" => "secret" },
      key_provider: provider
    )
    version = item.current_version
    old_ciphertext = version.ciphertext.dup
    old_wrapped = version.wrapped_dek.dup
    previous_active = Rails.configuration.x.vault.active_kek_id
    Rails.configuration.x.vault.active_kek_id = new_id
    provider.active_key_id = new_id

    result = with_registry_provider(provider) do
      Vault::RotateKeys.call(from: old_id, to: new_id)
    end

    version.reload
    assert_operator result.rotated, :>=, 1
    assert_equal TestSupport::InMemoryKeyProvider::PROVIDER_NAME, version.key_provider
    assert_equal new_id, version.kek_id
    assert_equal old_ciphertext, version.ciphertext
    refute_equal old_wrapped, version.wrapped_dek

    payload = Vault::RevealItem.call(user: user, item: item.reload, key_provider: provider, audit: false)
    assert_equal "memory rotation", payload["title"]
  ensure
    Rails.configuration.x.vault.active_kek_id = previous_active if defined?(previous_active) && previous_active
  end


  test "external KMS skeleton rotates through registry without becoming production-registered" do
    old_id = "kms-old"
    new_id = "kms-new"
    client = TestSupport::FakeKmsClient.new(
      keys: {
        old_id => OpenSSL::Random.random_bytes(32),
        new_id => OpenSSL::Random.random_bytes(32)
      }
    )
    old_provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: old_id,
      client: client
    )
    user = User.create!(
      email_address: "rotate-kms@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
    item = Vault::CreateItem.call(
      user: user,
      kind: "login",
      payload: { "schema" => "vault.login.v1", "title" => "kms rotation", "password" => "secret" },
      key_provider: old_provider
    )
    version = item.current_version
    old_ciphertext = version.ciphertext.dup
    old_wrapped = version.wrapped_dek.dup
    context = {
      user_id: user.id,
      vault_item_id: item.id,
      vault_item_version_id: version.id
    }
    old_dek_before_rotation = old_provider.unwrap_key(
      wrapped_key: old_wrapped,
      key_id: old_id,
      context: context
    )

    previous_active = Rails.configuration.x.vault.active_kek_id
    Rails.configuration.x.vault.active_kek_id = new_id
    new_provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: new_id,
      client: client
    )

    result = with_registry_provider(new_provider) do
      Vault::RotateKeys.call(from: old_id, to: new_id)
    end

    version.reload
    assert_operator result.rotated, :>=, 1
    assert_equal "external_kms_test", version.key_provider
    assert_equal new_id, version.kek_id
    assert_equal old_ciphertext, version.ciphertext
    refute_equal old_wrapped, version.wrapped_dek

    payload = Vault::RevealItem.call(user: user, item: item.reload, key_provider: new_provider, audit: false)
    assert_equal "kms rotation", payload["title"]

    historical_dek = old_provider.unwrap_key(
      wrapped_key: old_wrapped,
      key_id: old_id,
      context: context
    )
    assert_equal old_dek_before_rotation, historical_dek

    fresh_provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: new_id,
      client: client
    )
    recovered_payload = Vault::RevealItem.call(
      user: user,
      item: item.reload,
      key_provider: fresh_provider,
      audit: false
    )
    assert_equal "kms rotation", recovered_payload["title"]

    assert_raises(Crypto::UnknownKeyProviderError) { KeyProviders::Registry.fetch("external_kms") }
  ensure
    Rails.configuration.x.vault.active_kek_id = previous_active if defined?(previous_active) && previous_active
  end

  test "failed external KMS rotation rolls back all record updates" do
    old_id = "kms-rollback-old"
    new_id = "kms-rollback-new"
    keys = {
      old_id => OpenSSL::Random.random_bytes(32),
      new_id => OpenSSL::Random.random_bytes(32)
    }
    base_client = TestSupport::FakeKmsClient.new(keys: keys)

    old_provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: old_id,
      client: base_client
    )

    user = User.create!(
      email_address: "rotate-kms-rollback@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
    first = Vault::CreateItem.call(
      user: user,
      kind: "login",
      payload: { "schema" => "vault.login.v1", "title" => "rollback one", "password" => "secret" },
      key_provider: old_provider
    ).current_version
    second = Vault::CreateItem.call(
      user: user,
      kind: "login",
      payload: { "schema" => "vault.login.v1", "title" => "rollback two", "password" => "secret" },
      key_provider: old_provider
    ).current_version

    snapshots = [ first, second ].to_h { |version| [ version.id, [ version.wrapped_dek.dup, version.kek_id ] ] }

    failing_client = Class.new do
      def initialize(delegate)
        @delegate = delegate
        @encrypt_calls = 0
      end

      def key_available?(key_id:) = @delegate.key_available?(key_id: key_id)

      def encrypt(**params)
        @encrypt_calls += 1
        raise "simulated provider outage" if @encrypt_calls == 2

        @delegate.encrypt(**params)
      end

      def decrypt(**params) = @delegate.decrypt(**params)
    end.new(base_client)

    provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: new_id,
      client: failing_client
    )

    previous_active = Rails.configuration.x.vault.active_kek_id
    Rails.configuration.x.vault.active_kek_id = new_id

    error = assert_raises(Crypto::KeyProviderUnavailableError) do
      with_registry_provider(provider) do
        Vault::RotateKeys.call(from: old_id, to: new_id)
      end
    end
    assert_equal "KMS wrap unavailable", error.message

    [ first, second ].each do |version|
      version.reload
      wrapped, key_id = snapshots.fetch(version.id)
      assert_equal wrapped, version.wrapped_dek
      assert_equal key_id, version.kek_id
    end

    assert_equal 0, KeyRegistry.where(provider: "external_kms_test", kek_id: new_id).count
    assert_equal 1, AuditEvent.where(action: "key.rotation_started").count
    assert_equal 1, AuditEvent.where(action: "key.rotation_failed").count
    assert_equal 0, AuditEvent.where(action: "key.rotation_completed").count
  ensure
    Rails.configuration.x.vault.active_kek_id = previous_active if defined?(previous_active) && previous_active
  end

  private

  def with_registry_provider(provider)
    singleton = KeyProviders::Registry.singleton_class
    singleton.alias_method :fetch_without_test_provider, :fetch
    singleton.define_method(:fetch) { |*_args| provider }
    yield
  ensure
    singleton.alias_method :fetch, :fetch_without_test_provider if singleton&.method_defined?(:fetch_without_test_provider)
    singleton.remove_method :fetch_without_test_provider if singleton&.method_defined?(:fetch_without_test_provider)
  end

  def create_key(id)
    path = File.join(ENV.fetch("VAULT_KEK_DIR"), "#{id}.key")
    File.binwrite(path, OpenSSL::Random.random_bytes(32))
    File.chmod(0o600, path)
  end
end
