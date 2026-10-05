require "test_helper"

class SessionDevicePresenterTest < ActiveSupport::TestCase
  test "parses Chrome on Windows" do
    device = SessionDevicePresenter.for(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/152.0.0.0 Safari/537.36"
    )

    assert_equal "Chrome", device.browser
    assert_equal "Windows", device.operating_system
    assert_equal "Desktop", device.category
    assert_equal "Chrome on Windows", device.label
  end

  test "parses mobile Safari on iPhone" do
    device = SessionDevicePresenter.for(
      "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1"
    )

    assert_equal "Safari", device.browser
    assert_equal "iOS", device.operating_system
    assert_equal "Mobile", device.category
  end

  test "uses neutral fallback without fingerprinting unknown agents" do
    device = SessionDevicePresenter.for("custom-client/1.0")

    assert_equal "Unknown browser", device.browser
    assert_equal "Unknown OS", device.operating_system
    assert_equal "Desktop", device.category
  end
end
