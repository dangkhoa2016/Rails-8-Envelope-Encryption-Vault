require "test_helper"

class AuditRequestDetailsTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:user_agent, :request_method, :path, :remote_ip, keyword_init: true)

  test "keeps only bounded authentication metadata without query strings or headers" do
    input = FakeRequest.new(
      user_agent: "Chrome/125.0 (Synthetic)\r\nInjected-Header: no",
      request_method: "POST",
      path: "/session",
      remote_ip: "203.0.113.15"
    )
    details = Audit::RequestDetails.capture(input)
    assert_equal "203.0.113.15", details.fetch("ip_address")
    assert_equal "POST", details.fetch("http_method")
    assert_equal "/session", details.fetch("request_path")
    assert_match(/Chrome/, details.fetch("user_agent"))
    refute_match(/[\r\n]/, details.fetch("user_agent"))
    assert_equal %w[http_method ip_address request_path user_agent], details.keys.sort
    assert details.frozen?
  end

  test "rejects invalid IP and unknown request path rather than persisting unsafe input" do
    details = Audit::RequestDetails.capture(FakeRequest.new(
      user_agent: "x" * 300, request_method: "TRACE",
      path: "/session?password=do-not-log", remote_ip: "not-a-valid-IP"
    ))
    assert_equal 255, details.fetch("user_agent").length
    assert_nil details["ip_address"]
    assert_nil details["request_path"]
    assert_nil details["http_method"]
  end

  test "request metadata is attached only to known authentication audit actions" do
    snapshot = { "ip_address" => "203.0.113.15", "user_agent" => "Chrome/125",
                 "http_method" => "POST", "request_path" => "/session" }
    Current.set(audit_request_details: snapshot) do
      sign_in = AuditEvent.new(action: "user.login_succeeded", metadata: { "mfa" => true })
      assert sign_in.valid?
      assert_equal snapshot.fetch("ip_address"), sign_in.metadata.fetch("ip_address")
      assert_equal true, sign_in.metadata.fetch("mfa")

      vault = AuditEvent.new(action: "vault_item.revealed", metadata: {})
      assert vault.valid?
      assert_equal({}, vault.metadata)
    end
  end
end
