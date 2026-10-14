require "test_helper"

class SettingsSecurityRoutingTest < ActionDispatch::IntegrationTest
  test "settings security route resolves to singular SecurityController" do
    assert_routing(
      { path: "/settings/security", method: :get },
      { controller: "settings/security", action: "show" }
    )
  end
end
