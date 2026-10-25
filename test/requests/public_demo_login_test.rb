require "test_helper"

class PublicDemoLoginTest < ActionDispatch::IntegrationTest
  def with_demo_environment(mode:, published:)
    previous = %w[DEMO_MODE SHOW_PUBLIC_DEMO_CREDENTIALS DEMO_EMAIL DEMO_PASSWORD].to_h do |name|
      [ name, ENV[name] ]
    end
    ENV["DEMO_MODE"] = mode ? "true" : "false"
    ENV["SHOW_PUBLIC_DEMO_CREDENTIALS"] = published ? "true" : "false"
    ENV["DEMO_EMAIL"] = "showcase@example.test"
    ENV["DEMO_PASSWORD"] = "synthetic-public-password-9876"
    yield
  ensure
    previous.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end
  end

  test "public demo deliberately provides the shared synthetic login" do
    with_demo_environment(mode: true, published: true) do
      get new_session_path
      assert_response :success
      assert_select '[role="note"]', text: /Public test account/
      assert_includes response.body, "showcase@example.test"
      assert_includes response.body, "synthetic-public-password-9876"
    end
  end

  test "private production never reveals demo credentials" do
    with_demo_environment(mode: false, published: true) do
      get new_session_path
      assert_response :success
      assert_select '[role="note"]', text: /Public test account/, count: 0
      assert_not_includes response.body, "synthetic-public-password-9876"
    end
  end

  test "demo credential display needs its dedicated public flag" do
    with_demo_environment(mode: true, published: false) do
      get new_session_path
      assert_response :success
      assert_select '[role="note"]', text: /Public test account/, count: 0
      assert_not_includes response.body, "synthetic-public-password-9876"
    end
  end
end
