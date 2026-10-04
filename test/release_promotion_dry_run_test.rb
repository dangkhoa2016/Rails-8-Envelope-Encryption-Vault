require "test_helper"
require "open3"

class ReleasePromotionDryRunTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/release-promotion-dry-run")

  test "dry run composes existing release gates without promotion side effects" do
    script = SCRIPT.read

    assert_includes script, "release-seal-prepromote"
    assert_includes script, "RELEASE_REQUIRE_LIVE_AWS_KMS=1"
    assert_includes script, "release-prepare-promotion"
    assert_includes script, "production-database-name"
    assert_includes script, "stable-database-preexists"
    assert_includes script, "stable-database-cleanup-failed"
    assert_includes script, "current-not-expected-production"
    assert_includes script, "current-changed"
    assert_includes script, "production-health-regressed"
    assert_includes script, "M4_DRY_RUN=PASS"

    refute_includes script, "ln -sfn"
    refute_includes script, "script/start-production"
    refute_includes script, "RELEASE_PHASE=promoted"
  end

  test "cleanup is armed before promotion preparation and disarmed after explicit database drop" do
    script = SCRIPT.read

    arm = script.index("cleanup_armed=1")
    prepare = script.index("release-prepare-promotion")
    drop = script.rindex("dropdb")
    disarm = script.rindex("cleanup_armed=0")

    assert arm
    assert prepare
    assert drop
    assert disarm
    assert_operator arm, :<, prepare
    assert_operator prepare, :<, drop
    assert_operator drop, :<, disarm
  end

  test "sanitized readiness summary records dry-run invariants" do
    script = SCRIPT.read

    assert_includes script, '"current_unchanged": True'
    assert_includes script, '"repoint_performed": False'
    assert_includes script, '"production_start_performed": False'
    assert_includes script, '"stable_database_cleanup": "pass"'
    assert_includes script, '"credential_values_recorded": False'
    assert_includes script, '"key_ids_recorded": False'
    assert_includes script, '"plaintext_recorded": False'
  end

  test "help exits before executing the flow" do
    _stdout, stderr, status = Open3.capture3(SCRIPT.to_s, "--help")

    refute status.success?
    assert_equal 64, status.exitstatus
    assert_includes stderr, "usage: script/release-promotion-dry-run"
    refute_includes stderr, "M4_DRY_RUN=PASS"
  end
end
