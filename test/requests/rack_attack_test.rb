require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store.clear
  end

  test "login endpoint is throttled by IP" do
    5.times do
      post session_path, params: { email_address: "nobody@example.test", password: "wrong-password" }
      assert_response :redirect
    end
    post session_path, params: { email_address: "nobody@example.test", password: "wrong-password" }
    assert_response :too_many_requests
    assert response.headers["Retry-After"].present?
  end

  test "login endpoint is throttled by normalized account across IPs" do
    10.times do |index|
      post session_path,
        params: { email_address: "TARGET@Example.Test", password: "wrong-password" },
        headers: { "REMOTE_ADDR" => "198.51.100.#{index + 1}" }
      assert_response :redirect
    end

    post session_path,
      params: { email_address: "target@example.test", password: "wrong-password" },
      headers: { "REMOTE_ADDR" => "203.0.113.50" }
    assert_response :too_many_requests
  end
end
