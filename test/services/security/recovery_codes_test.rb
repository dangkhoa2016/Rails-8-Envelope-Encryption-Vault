require "test_helper"

class RecoveryCodesTest < ActiveSupport::TestCase
  test "recovery code is accepted once and then consumed" do
    user = User.new(email_address: "recovery-service@example.test")
    user.password_digest = BCrypt::Password.create(SecureRandom.hex(32))
    user.save!

    secret = Security::Totp.generate_secret
    Mfa::SecretStore.enable!(user: user, secret: secret)
    code = Mfa::RecoveryCodes.regenerate!(user: user).first

    assert Mfa::Verifier.verify(user: user, candidate: code)
    refute Mfa::Verifier.verify(user: user, candidate: code)
    assert_equal 1, user.mfa_recovery_codes.where.not(used_at: nil).count
  end
end
