require "test_helper"
require "open3"

class CsrfOriginPreflightCleanupTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/production-csrf-origin-preflight")

  test "server cleanup is bounded and has forced termination fallback" do
    script = SCRIPT.read
    cleanup = script[/cleanup\(\) \{.*?\n\}/m]

    assert cleanup
    assert_includes cleanup, 'kill "$server_pid"'
    assert_includes cleanup, "for _ in \$(seq 1 30)"
    assert_includes cleanup, 'kill -0 "$server_pid"'
    assert_includes cleanup, "sleep 0.1"
    assert_includes cleanup, 'kill -9 "$server_pid"'
    assert_includes cleanup, 'wait "$server_pid"'
  end

  test "script remains valid bash" do
    _stdout, stderr, status = Open3.capture3("bash", "-n", SCRIPT.to_s)
    assert status.success?, stderr
  end
end
