require "test_helper"

class MfaSecretStoreTest < ActiveSupport::TestCase
  test "TOTP seed is envelope encrypted and recoverable" do
    user = User.create!(email_address: "mfa@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    secret = Security::Totp.generate_secret
    setting = Mfa::SecretStore.enable!(user: user, secret: secret)

    refute_includes setting.ciphertext, secret
    assert_equal secret, Mfa::SecretStore.secret_for(user: user.reload)
  end

  test "pending setup seed is encrypted server side and expires" do
    user = User.create!(email_address: "mfa-pending@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    setting = Mfa::SecretStore.begin_setup!(user: user)
    refute setting.enabled?
    secret = Mfa::SecretStore.secret_for(user: user.reload, allow_pending: true)
    refute_includes setting.ciphertext, secret
    setting.update_column(:setup_expires_at, 1.minute.ago)
    assert_raises(ArgumentError) { Mfa::SecretStore.secret_for(user: user.reload, allow_pending: true) }
  end
end
