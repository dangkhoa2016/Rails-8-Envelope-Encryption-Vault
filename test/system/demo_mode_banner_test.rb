require "application_system_test_case"

class DemoModeBannerTest < ApplicationSystemTestCase
  test "demo mode visibly warns users to use synthetic data only" do
    previous = ENV["DEMO_MODE"]
    ENV["DEMO_MODE"] = "true"

    visit new_session_path
    assert_selector "[data-demo-banner]", text: "Demo environment — synthetic data only."
    assert_text "Do not enter real secrets."
  ensure
    ENV["DEMO_MODE"] = previous
  end
end
