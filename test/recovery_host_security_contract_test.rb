require "test_helper"

class RecoveryHostSecurityContractTest < ActiveSupport::TestCase
  test "production failure handling preflight proves safe branded errors and correlation" do
    script = Rails.root.join("script/production-error-preflight").read
    production = Rails.root.join("config/environments/production.rb").read
    routes = Rails.root.join("config/routes.rb").read
    controller = Rails.root.join("app/controllers/errors_controller.rb").read

    assert_includes script, "PRODUCTION_ERROR_PREFLIGHT=PASS"
    assert_includes script, "ERROR_CORRELATION=PASS"
    assert_includes script, "ERROR_SECRET_VALUES=ABSENT"
    assert_includes script, "fix42-404-correlation"
    assert_includes script, "fix42-422-correlation"
    assert_includes script, "fix42-500-correlation"
    assert_includes production, "config.exceptions_app"
    assert_includes routes, 'ENV["ERROR_PREFLIGHT_PROBE"] == "true"'
    assert_includes controller, 'response.headers["Cache-Control"] = "no-store"'
    refute_includes controller, "exception.message"
    refute_includes controller, "backtrace"
  end
  test "production logging redaction preflight proves sensitive request values are filtered" do
    script = Rails.root.join("script/production-logging-redaction-preflight").read
    routes = Rails.root.join("config/routes.rb").read
    filters = Rails.root.join("config/initializers/filter_parameter_logging.rb").read

    assert_includes script, "LOGGING_REDACTION_PREFLIGHT=PASS"
    assert_includes script, "LOGGING_SECRET_VALUES=ABSENT"
    assert_includes script, "[FILTERED]"
    assert_includes script, "plaintext_canary_values_exposed"
    assert_includes routes, 'ENV["LOGGING_PREFLIGHT_PROBE"] == "true"'
    %w[passw secret_value token email_address env_text q ciphertext nonce].each do |key|
      assert_includes filters, key
    end
  end
  test "CSRF origin preflight proves same-origin acceptance and cross-site rejection" do
    script = Rails.root.join("script/production-csrf-origin-preflight").read
    production = Rails.root.join("config/environments/production.rb").read
    assert_includes production, "forgery_protection_origin_check = true"
    assert_includes script, "CSRF_ORIGIN_PREFLIGHT=PASS"
    assert_includes script, "CSRF_SECRET_VALUES=ABSENT"
    assert_includes script, "foreign_origin_rejected=PASS"
    assert_includes script, "null_origin_rejected=PASS"
    assert_includes script, "missing_token_rejected=PASS"
    assert_includes script, "plaintext_canary_values_exposed"
  end
  test "production rate-limit preflight proves abuse controls and stateless 429 handling" do
    script = Rails.root.join("script/production-rate-limit-preflight").read
    app = Rails.root.join("config/application.rb").read
    boundary = Rails.root.join("lib/rate_limit_boundary.rb").read
    assert_includes script, "RATE_LIMIT_PREFLIGHT=PASS"
    assert_includes script, "RATE_LIMIT_SECRET_VALUES=ABSENT"
    assert_includes script, "login_account_throttle=PASS"
    assert_includes script, "global_ip_throttle=PASS"
    assert_includes script, 'global_ip="192.0.2.$(( $$ % 200 + 1 ))"'
    assert_includes script, '-H "X-Forwarded-For: $login_ip"'
    assert_includes script, '-H "X-Forwarded-For: $global_ip"'
    assert_includes script, "account_email_upper"
    assert_includes script, "GLOBAL_THROTTLE_PRESEED=PASS"
    assert_includes script, "wait_for_fixed_window 60 8"
    assert_includes script, "wait_for_fixed_window 600 15"
    assert_operator script.index("wait_for_fixed_window 60 8"), :<, script.index("for i in $(seq 1 6)")
    assert_operator script.index("wait_for_fixed_window 600 15"), :<, script.index("for i in $(seq 1 10)")
    assert_includes script, "throttle.limit == 300"
    assert_includes script, "throttle.period == 60"
    assert_includes script, "cache.store.write(key, 299"
    assert_includes script, '"global_probe_strategy":"preseed_299_plus_two_http_requests"'
    assert_includes script, '"global_request_300_status":global_codes[0]'
    assert_includes script, '"global_request_301_status":global_codes[1]'
    refute_includes script, "seq 1 301"
    refute_includes script, "for attempt in 1 2"
    refute_includes script, "ThreadPoolExecutor"
    assert_includes app, "RateLimitBoundary"
    assert_includes boundary, "Rack::Attack.new(app)"
  end
  test "production session lifecycle preflight proves rotation revocation and timeout behavior" do
    script = Rails.root.join("script/production-session-lifecycle-preflight").read
    assert_includes script, "SESSION_LIFECYCLE_PREFLIGHT=PASS"
    assert_includes script, "SESSION_LIFECYCLE_SECRET_VALUES=ABSENT"
    assert_includes script, "reauth_session_rotation=PASS"
    assert_includes script, "stale_cookie_rejection=PASS"
    assert_includes script, "other_session_revocation=PASS"
    assert_includes script, "current_session_revocation=PASS"
    assert_includes script, "idle_timeout_rejection=PASS"
    assert_includes script, "absolute_timeout_rejection=PASS"
  end

  test "upgrade consolidation preflight preserves FIX46 database contract" do
    script = Rails.root.join("script/upgrade-baseline-preflight").read
    assert_includes script, "UPGRADE_FROM_FIX46_PREFLIGHT=PASS"
    assert_includes script, "UPGRADE_PREFLIGHT_SECRET_VALUES=ABSENT"
    assert_includes script, "migration set differs from FIX46"
    assert_includes script, "pending migrations remain"
    assert_includes script, "db:migrate"
    assert_includes script, "UPGRADE_BASE_ROOT"
    assert_includes script, 'EXPECTED_BASE_VERSION="0.1.2-FIX46"'
    assert_includes script, "20260927001300_add_totp_replay_protection.rb"
    refute_includes script, "/mnt/workspace/ruby-envelope-vault/FIX46"
  end

  test "production boot checks are provider aware and validate AWS KMS registry authority" do
    check = Rails.root.join("config/initializers/production_environment_check.rb").read

    assert_includes check, 'when "local_file"'
    assert_includes check, '"VAULT_KEK_DIR is required"'
    assert_includes check, 'when "aws_kms"'
    assert_includes check, '"AWS_REGION or AWS_DEFAULT_REGION is required for aws_kms"'
    assert_includes check, 'provider == "local_file"'
    assert_includes check, 'VAULT_KEY_PROVIDER=#{provider.inspect} is not supported by this release'
    assert_includes check, "Rails.application.config.after_initialize"
    assert_includes check, "KeyProviders::AwsKmsActiveKeyGuard.verify!"
    assert_includes check, "Production AWS KMS registry checks failed"
    refute_includes check, 'unless provider == "local_file"'
  end

  test "operator readiness paths enforce AWS KMS active registry guard without printing key ids" do
    readiness = Rails.root.join("script/aws-kms-readiness").read
    ops_check = Rails.root.join("script/ops-check").read
    controller = Rails.root.join("app/controllers/health_controller.rb").read
    diagnostics = Rails.root.join("app/services/key_providers/diagnostics.rb").read

    assert_includes readiness, "AWS_KMS_REGISTRY_ACTIVE_MATCH=PASS"
    assert_includes readiness, "AWS_KMS_REGISTRY_ACTIVE_MATCH=FAIL"
    assert_includes readiness, "provider.assert_write_allowed!"
    assert_includes ops_check, "provider.assert_write_allowed!"
    assert_includes controller, "provider.assert_write_allowed!"
    assert_includes diagnostics, "provider.assert_write_allowed!"

    refute_includes readiness, 'puts ENV["AWS_KMS_KEY_ID"]'
    refute_includes readiness, 'puts ENV["VAULT_ACTIVE_KEK_ID"]'
  end

  test "key provider diagnostics expose only safe operator fields" do
    provider_status = Rails.root.join("script/key-provider-status").read
    operator_status = Rails.root.join("script/operator-status").read

    %w[KEY_PROVIDER_NAME KEY_PROVIDER_STATUS KEY_PROVIDER_CATEGORY KEY_PROVIDER_REMOTE].each do |token|
      assert_includes provider_status, token
      assert_includes operator_status, token
    end

    assert_includes operator_status, '"$key_provider_status" == "ready"'
    refute_includes provider_status, "VAULT_ACTIVE_KEK_ID"
    refute_includes provider_status, "AWS_ACCESS_KEY_ID"
    refute_includes provider_status, "AWS_SECRET_ACCESS_KEY"
    refute_includes provider_status, "AWS_SESSION_TOKEN"
    refute_includes provider_status, "AWS_REGION="
    refute_includes operator_status, "VAULT_ACTIVE_KEK_ID"
    refute_includes operator_status, "AWS_ACCESS_KEY_ID"
    refute_includes operator_status, "AWS_SECRET_ACCESS_KEY"
    refute_includes operator_status, "AWS_SESSION_TOKEN"
  end

  test "fresh-host KMS rehearsal preserves live-evidence boundary and secret redaction" do
    script = Rails.root.join("script/aws-kms-fresh-host-rehearsal").read

    assert_includes script, "AWS_KMS_FRESH_HOST_SYNTHETIC=PASS"
    assert_includes script, "AWS_KMS_FRESH_HOST_LIVE_STATUS"
    assert_includes script, "aws-kms-readiness"
    assert_includes script, "aws-kms-live-smoke"
    assert_includes script, "AWS_KMS_SECRET_FILE"
    assert_includes script, "AWS_KMS_FIX_SECRET_MODE"
    assert_includes script, "script/prepare-secret-env"
    assert_includes script, "script/aws-kms-secret-preflight"
    assert_includes script, "AWS_KMS_SECRET_INTAKE=PASS"
    assert_includes script, '"secret_intake": os.environ["SECRET_INTAKE_STATUS"]'
    assert_includes script, '"credential_values_recorded": False'
    assert_includes script, '"key_ids_recorded": False'
    assert_includes script, '"live_smoke": os.environ["LIVE_SMOKE"]'
    refute_includes script, "AWS_SECRET_ACCESS_KEY="
    refute_includes script, "AWS_ACCESS_KEY_ID="
    refute_includes script, "AWS_SESSION_TOKEN="
  end

  test "live AWS KMS scripts bootstrap Bundler explicitly" do
    %w[
      script/aws-kms-live-smoke
      script/aws-kms-live-two-key
      script/aws-kms-live-vault-rotation
    ].each do |path|
      script = Rails.root.join(path).read
      assert_includes script, 'require "bundler/setup"'
    end
  end

  test "postpromote full private restore orchestrator is explicit and non-promoting by default" do
    script = Rails.root.join("script/restore-postpromote-full-private").read

    assert_includes script, "POSTPROMOTE_INTERNAL_MANIFEST=PASS"
    assert_includes script, "POSTPROMOTE_BUNDLE_METADATA=PASS"
    assert_includes script, "POSTPROMOTE_SOURCE_VERIFY=PASS"
    assert_includes script, 'reconstructed_name="reconstructed-authority-$version"'
    assert_includes script, 'release_secrets_name="release-secrets-$version"'
    assert_includes script, "reason=missing-release-secrets"
    assert_includes script, "reason=missing-private-authority"
    assert_includes script, '[[ -f "$private/ruby-encrypt-env" ]]'
    assert_includes script, '[[ -f "$private/production.env" ]]'
    assert_operator script.index('[[ -d "$private/$release_secrets_name" ]]'), :<, script.index('cp -a "$rc_src" "$rc_dst"')
    assert_operator script.index('[[ -f "$private/ruby-encrypt-env" ]]'), :<, script.index('cp -a "$rc_src" "$rc_dst"')
    assert_operator script.index('[[ -f "$private/production.env" ]]'), :<, script.index('cp -a "$rc_src" "$rc_dst"')
    assert_includes script, "RUBY-ENVELOPE-VAULT-v*-PRIVATE-DR-PROMOTED-*"
    refute_includes script, "release-secrets-0.1.8"
    refute_includes script, "reconstructed-authority-0.1.8"
    assert_includes script, '"$HOTFIX_ROOT/script/rebuild-production-env"'
    assert_includes script, '--release-root "$rc_dst"'
    refute_includes script, '"$rc_dst/script/rebuild-production-env"'
    assert_includes script, 'bootstrap.sh" setup'
    assert_includes script, 'export RUNTIME_ROOT="$runtime_root"'
    assert_operator script.index('export RUNTIME_ROOT="$runtime_root"'), :<, script.index('bootstrap.sh" setup')
    assert_includes script, "POSTPROMOTE_DATABASE_CATALOG=PASS"
    assert_includes script, "reason=pg_restore-missing"
    assert_includes script, 'sha256sum "$dump" > "$dump.sha256"'
    assert_includes script, "POSTPROMOTE_DATABASE_SIDECAR=PASS"
    assert_includes script, "POSTPROMOTE_DATABASE_RESTORE=PASS"
    assert_includes script, "--repoint-current"
    assert_includes script, "--start-production"
    assert_includes script, 'if [[ "$repoint" == "1" ]]'
    assert_includes script, 'if [[ "$start_production" == "1" ]]'
    assert_includes script, "start-requires-repoint"
  end
end
