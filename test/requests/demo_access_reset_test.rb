require "test_helper"

class DemoAccessResetTest < ActionDispatch::IntegrationTest
  DEFAULT_PASSWORD = "synthetic-demo-password-2026"
  MUTATED_PASSWORD = "changed-synthetic-password-2026"

  def with_public_demo
    names = %w[
      DEMO_MODE SHOW_PUBLIC_DEMO_CREDENTIALS PUBLIC_DEMO_RESET_ENABLED
      ALLOW_SIGNUPS REQUIRE_MFA DEMO_EMAIL DEMO_PASSWORD
    ]
    previous = names.to_h { |name| [ name, ENV[name] ] }
    ENV.update(
      "DEMO_MODE" => "true", "SHOW_PUBLIC_DEMO_CREDENTIALS" => "true",
      "PUBLIC_DEMO_RESET_ENABLED" => "true", "ALLOW_SIGNUPS" => "false",
      "REQUIRE_MFA" => "false", "DEMO_EMAIL" => Demo::FixtureBuilder::DEMO_EMAIL,
      "DEMO_PASSWORD" => DEFAULT_PASSWORD
    )
    yield
  ensure
    previous.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end
  end

  def demo_user
    User.create!(
      email_address: Demo::FixtureBuilder::DEMO_EMAIL,
      password: MUTATED_PASSWORD, password_confirmation: MUTATED_PASSWORD
    )
  end

  test "demo reset restores password and clears MFA" do
    with_public_demo do
      user = demo_user
      Mfa::SecretStore.enable!(user: user, secret: Security::Totp.generate_secret)
      Mfa::RecoveryCodes.regenerate!(user: user)
      post demo_access_reset_path
      assert_response :see_other
      assert_nil user.reload.mfa_setting
      assert_equal 0, user.mfa_recovery_codes.count
      assert User.authenticate_by(email_address: user.email_address, password: DEFAULT_PASSWORD)
    end
  end

  test "private cannot reset shared demo credentials" do
    with_public_demo do
      user = demo_user
      ENV["DEMO_MODE"] = "false"
      post demo_access_reset_path
      assert_response :not_found
      assert User.authenticate_by(email_address: user.email_address, password: MUTATED_PASSWORD)
    end
  end

  test "missing enable flag fails closed" do
    with_public_demo do
      demo_user
      ENV["PUBLIC_DEMO_RESET_ENABLED"] = "false"
      post demo_access_reset_path
      assert_response :not_found
      get new_session_path
      assert_select 'form[action="/demo_access_reset"]', count: 0
    end
  end

  test "unavailable demo account cannot create a new account" do
    with_public_demo do
      assert_no_difference("User.count") do
        post demo_access_reset_path
        assert_response :not_found
      end
    end
  end

  test "reset revokes sessions and clears pending MFA setup" do
    with_public_demo do
      user = demo_user
      Mfa::SecretStore.begin_setup!(user: user)
      session = user.sessions.create!(last_seen_at: Time.current, absolute_expires_at: Time.current + 1.day)
      post demo_access_reset_path
      assert_response :see_other
      assert_nil user.reload.mfa_setting
      assert_not session.reload.active?
    end
  end

  test "rate limiting prevents repeated disruptive resets" do
    with_public_demo do
      demo_user
      2.times do
        post demo_access_reset_path
        assert_response :see_other
      end
      post demo_access_reset_path
      assert_response :too_many_requests
    end
  end
end
