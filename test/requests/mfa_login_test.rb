require "test_helper"

class MfaLoginTest < ActionDispatch::IntegrationTest
  test "password login pauses for MFA when enabled" do
    user = User.create!(email_address: "mfa-login@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    secret = Security::Totp.generate_secret
    Mfa::SecretStore.enable!(user: user, secret: secret)
    Mfa::RecoveryCodes.regenerate!(user: user)

    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    assert_redirected_to new_mfa_challenge_path

    token = Security::Totp.code(secret: secret, at: Time.current)
    post mfa_challenge_path, params: { token: token }
    assert_redirected_to root_path
    assert user.sessions.reload.active.exists?
  end

  test "password login accepts an unused MFA recovery code" do
    user = User.create!(email_address: "mfa-recovery-login@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    secret = Security::Totp.generate_secret
    Mfa::SecretStore.enable!(user: user, secret: secret)
    recovery_code = Mfa::RecoveryCodes.regenerate!(user: user).first

    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    assert_redirected_to new_mfa_challenge_path

    post mfa_challenge_path, params: { token: recovery_code }
    assert_redirected_to root_path
    assert_equal 1, user.mfa_recovery_codes.reload.where.not(used_at: nil).count
  end
end
