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

  test "failed recovery verification keeps its entry method and never echoes the token" do
    user = User.create!(
      email_address: "mfa-invalid-recovery@example.test",
      password: "long-password-1234", password_confirmation: "long-password-1234"
    )
    Mfa::SecretStore.enable!(user: user, secret: Security::Totp.generate_secret)
    Mfa::RecoveryCodes.regenerate!(user: user)

    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    assert_redirected_to new_mfa_challenge_path
    get new_mfa_challenge_path(method: "recovery")
    assert_response :success
    assert_select 'turbo-frame[id="mfa_verification"]'
    assert_select 'input[name="token"][inputmode="text"][maxlength="19"]'
    assert_select 'input[name="code_method"][value="recovery"]'
    assert_select 'a[data-mfa-method="recovery"][aria-current="page"]'

    post mfa_challenge_path, params: { token: "FFFF-FFFF-FFFF-FFFF", code_method: "recovery" }
    assert_redirected_to new_mfa_challenge_path(method: "recovery")
    follow_redirect!
    assert_response :success
    assert_select "#mfa-challenge-error", text: /couldn't verify/
    assert_select 'input[name="token"][value="FFFF-FFFF-FFFF-FFFF"]', false
    assert_not_includes response.body, "FFFF-FFFF-FFFF-FFFF"
    assert_equal 0, user.mfa_recovery_codes.reload.where.not(used_at: nil).count
  end

  test "authenticator challenge is the default with numeric keyboard and code hints" do
    user = User.create!(
      email_address: "mfa-auth-ui@example.test",
      password: "long-password-1234", password_confirmation: "long-password-1234"
    )
    Mfa::SecretStore.enable!(user: user, secret: Security::Totp.generate_secret)
    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    get new_mfa_challenge_path
    assert_response :success
    assert_select 'input[name="token"][inputmode="numeric"][maxlength="6"]'
    assert_select 'a[data-mfa-method="authenticator"][aria-current="page"]'
    assert_select 'input[name="code_method"][value="authenticator"]'
    assert_select 'form[data-turbo-frame="_top"]'
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
