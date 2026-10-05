ENV["SE_CACHE_PATH"] ||= File.expand_path("../tmp/selenium", __dir__)

require "test_helper"

Capybara.default_max_wait_time = 20

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  TEST_PASSWORD = "system-test-password-1234"

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
  end

  setup do
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
    Current.reset if defined?(Current)
    page.current_window.resize_to(1400, 1400)
  end

  teardown do
    page.current_window.resize_to(1400, 1400) if page&.current_window
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
    Current.reset if defined?(Current)
  rescue Selenium::WebDriver::Error::WebDriverError
    Current.reset if defined?(Current)
  end

  private

  def create_system_user(email)
    User.create!(email_address: email, password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
  end

  def sign_in_system_user(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: TEST_PASSWORD
    click_button "Sign in"
    assert_current_path root_path
    assert_selector "[data-dashboard-main-grid]"
  end
end
