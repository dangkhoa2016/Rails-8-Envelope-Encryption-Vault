require "test_helper"

class RecoveryContractTest < ActiveSupport::TestCase
  test "version matches the DEV RC or RELEASE tree contract" do
    tree = Rails.root.basename.to_s
    expected = if tree.start_with?("DEV-")
      "#{tree.delete_prefix("DEV-")}-dev"
    elsif tree.start_with?("RC-")
      tree.delete_prefix("RC-")
    elsif tree.start_with?("RELEASE-")
      tree.delete_prefix("RELEASE-")
    else
      flunk "unexpected release tree name: #{tree}"
    end

    assert_equal expected, Rails.root.join("VERSION").read.strip
  end

  test "portable activation helper is self locating with host runtime fallbacks" do
    activation = Rails.root.join("activate-runtime.sh").read
    compatibility = Rails.root.join("activate-kaggle.sh").read

    assert_includes activation, 'ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"'
    assert_includes activation, "/kaggle/working/.ruby-envelope-vault-runtime"
    assert_includes activation, "/content/.ruby-envelope-vault-runtime"
    assert_includes activation, "XDG_STATE_HOME"
    assert_includes activation, 'export BUNDLE_PATH="$RUNTIME_ROOT/bundle"'
    assert_includes activation, 'export SE_CACHE_PATH="${SE_CACHE_PATH:-$RUNTIME_ROOT/selenium}"'
    assert_includes compatibility, 'source "$ROOT/activate-runtime.sh"'
  end


  test "bootstrap self heals persistent browser runtime and respects START_SERVER" do
    bootstrap = Rails.root.join("bootstrap.sh").read
    assert_includes bootstrap, 'export BUNDLE_PATH="$BUNDLE_DIR"'
    assert_includes bootstrap, 'export SE_CACHE_PATH="$SELENIUM_CACHE_DIR"'
    assert_includes bootstrap, 'for selenium_dir in "$SELENIUM_CACHE_DIR" "$ROOT/tmp/selenium"'
    assert_includes bootstrap, "libatk-bridge2.0-0"
    assert_includes bootstrap, 'if [[ "$START_SERVER" == "1" ]]; then'
    assert_includes bootstrap, "START_SERVER=0: services are ready; Rails server not started"
  end


  test "bootstrap selects an available ALSA runtime package across Ubuntu generations" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, "apt_first_available"
    assert_includes bootstrap, "libasound2t64"
    assert_includes bootstrap, "libasound2"
    assert_includes bootstrap, 'libasound_package="$(apt_first_available libasound2t64 libasound2)"'
    assert_includes bootstrap, 'fonts-liberation "$libasound_package"'
    refute_includes bootstrap, "fonts-liberation libasound2 "
  end

  test "bootstrap preserves selected PostgreSQL port for Unix socket provisioning" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, '-h "$PGSOCKET" -p "$PG_PORT" -d postgres'
    assert_includes bootstrap, 'createdb" -h "$PGSOCKET" -p "$PG_PORT"'
    assert_includes bootstrap, "Preferred PostgreSQL port is busy; using $requested_port"
  end

  test "bootstrap reuses the Redis port from its private managed config" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, "redis_managed_port()"
    assert_includes bootstrap, '$1 == "port" && $2 ~ /^[0-9]+$/'
    assert_includes bootstrap, 'REDIS_PORT="$(redis_managed_port || true)"'
    assert_includes bootstrap, "private runtime config is the source of truth"
    refute_includes bootstrap, 'REDIS_PORT="${REDIS_PORT:-$PREFERRED_REDIS_PORT}"'
  end

  test "bootstrap repairs persistent mise executable mode before install" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, "Repairing executable mode for persistent runtime tool:"
    assert_match(/repair_executable_modes.*install_mise_and_ruby/m, bootstrap)
  end


  test "accessibility stylesheet provides focus and reduced-motion safeguards" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_includes css, ":focus-visible"
    assert_includes css, "prefers-reduced-motion: reduce"
  end

  test "recovery provenance exists" do
    provenance = Rails.root.join("RECOVERY-PROVENANCE.md")
    assert provenance.exist?
    assert_includes provenance.read, "avoids claiming byte-identical provenance"
  end
  test "bootstrap emits stable recovery observability summary" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, "RECOVERY_SUMMARY_BEGIN"
    assert_includes bootstrap, "reused_tools=$OBS_REUSED_TOOLS"
    assert_includes bootstrap, "repaired_modes=$OBS_REPAIRED_MODES"
    assert_includes bootstrap, "installed_packages=$OBS_INSTALLED_PACKAGES"
    assert_includes bootstrap, "assets_rebuilt=$OBS_ASSETS_REBUILT"
    assert_includes bootstrap, "database_reused=$OBS_DATABASE_REUSED"
    assert_includes bootstrap, "postgres_reused=$OBS_POSTGRES_REUSED"
    assert_includes bootstrap, "redis_reused=$OBS_REDIS_REUSED"
    assert_includes bootstrap, "RECOVERY_SUMMARY_END"
  end
  test "bootstrap persists a non-secret machine-readable recovery summary" do
    bootstrap = Rails.root.join("bootstrap.sh").read

    assert_includes bootstrap, 'LATEST_BOOTSTRAP_SUMMARY="$DIAGNOSTICS_DIR/latest-bootstrap-summary.json"'
    assert_includes bootstrap, '"schema_version": 1'
    assert_includes bootstrap, '"reused_tools"'
    assert_includes bootstrap, '"repaired_modes"'
    assert_includes bootstrap, '"installed_packages"'
    assert_includes bootstrap, '"database_reused"'
    assert_includes bootstrap, 'chmod 644 "$LATEST_BOOTSTRAP_SUMMARY"'
    refute_includes bootstrap, '"database_url"'
    refute_includes bootstrap, '"redis_url"'
    refute_includes bootstrap, '"secret_key_base"'
  end

  test "release verification script preserves required gates" do
    verifier = Rails.root.join("script/release-verify").read

    %w[repository-policy portability-check zeitwerk test test:system rubocop brakeman bundler-audit crypto-self-test security-self-test accessibility-smoke].each do |contract|
      assert_includes verifier, contract
    end
    assert_includes verifier, "RELEASE_VERIFY=PASS"
  end
  test "pre-promotion release sealing keeps an explicit promotion stop" do
    seal = Rails.root.join("script/release-seal-prepromote").read

    assert_includes seal, "./script/release-verify"
    assert_includes seal, "./script/build-current-migration-bundle"
    assert_includes seal, "production-ux-accessibility-preflight"
    assert_includes seal, "production-http-security-preflight"
    assert_includes seal, "production-error-preflight"
    assert_includes seal, "production-logging-redaction-preflight"
    assert_includes seal, "production-csrf-origin-preflight"
    assert_includes seal, "production-rate-limit-preflight"
    assert_includes seal, "production-session-lifecycle-preflight"
    assert_includes seal, "upgrade-from-fix46-preflight"
    assert_includes seal, "RELEASE_REQUIRE_LIVE_AWS_KMS"
    assert_includes seal, "aws-kms-fresh-host-rehearsal"
    assert_includes seal, "AWS-KMS-FRESH-HOST-SUMMARY.json"
    assert_includes seal, "RELEASE_REQUIRE_PRIVATE_DR"
    assert_includes seal, "private-dr-restore-acceptance"
    assert_includes seal, "PRIVATE-DR-RESTORE-ACCEPTANCE.json"
    assert_includes seal, "RELEASE_PRIVATE_DR_PROVENANCE_FILE"
    assert_includes seal, "private-dr-provenance-preflight"
    assert_includes seal, "PRIVATE-DR-PROVENANCE.json"
    assert_includes seal, "${RELEASE_NAME}_ISOLATED_RESTORE=PASS"
    assert_includes seal, "PREPROMOTE_SEAL=PASS"
    assert_includes seal, "PROMOTION_REQUIRED=yes"
    refute_includes seal, "ln -sfn"
    refute_includes seal, "tmux respawn-window"
  end

  test "release metadata is non-secret and records artifact verification state" do
    metadata = Rails.root.join("script/release-metadata").read

    %w[release_version generated_at phase release_verify artifact_sha256 isolated_restore offhost_roundtrip public_package_integrity public_package_links_checked public_package_screenshots public_package_root_files public_package_manifest_rows sealed_source_integrity sealed_source_file_count sealed_source_manifest_sha256 new_host_recovery new_host_bootstrap_mode new_host_database_reused new_host_postgres_reused new_host_redis_reused new_host_recovery_summary_sha256 ux_accessibility_preflight ux_accessibility_manual_status ux_accessibility_wcag_conformance_claimed ux_accessibility_preflight_sha256 http_security_preflight http_security_secret_values_absent http_security_preflight_sha256 production_error_preflight production_error_status_404 production_error_status_422 production_error_status_500 production_error_request_id_correlation production_error_stack_trace_exposed production_error_local_filesystem_path_exposed production_error_secret_values_absent production_error_preflight_sha256 logging_redaction_preflight logging_redaction_sensitive_parameter_count logging_redaction_request_id_correlation logging_redaction_plaintext_canary_values_exposed logging_redaction_secret_values_absent logging_redaction_preflight_sha256 csrf_origin_preflight csrf_origin_check_enabled csrf_same_origin_valid_token_status csrf_foreign_origin_status csrf_null_origin_status csrf_missing_token_status csrf_request_id_log_correlation csrf_secret_values_absent csrf_origin_preflight_sha256 rate_limit_preflight rate_limit_login_ip_limit rate_limit_login_account_limit rate_limit_global_ip_limit rate_limit_throttled_status rate_limit_retry_after_present rate_limit_cache_control_no_store rate_limit_session_cookie_on_throttle rate_limit_health_safelist rate_limit_request_id_log_correlation rate_limit_cache_store_class rate_limit_secret_values_absent rate_limit_preflight_sha256 session_lifecycle_preflight session_login_creation session_cookie_httponly session_cookie_same_site_strict session_cookie_has_expiry session_reauthentication_rotation session_stale_cookie_rejection session_other_revocation session_current_revocation session_idle_timeout_rejection session_absolute_timeout_rejection session_secret_values_absent session_lifecycle_preflight_sha256 upgrade_from_fix46_preflight upgrade_base_version upgrade_migration_set_identical upgrade_db_migrate_idempotent upgrade_pending_migrations upgrade_persistent_database_reused upgrade_project_doctor upgrade_secret_values_absent upgrade_preflight_sha256 aws_kms_fresh_host_rehearsal aws_kms_live_ready aws_kms_live_smoke aws_kms_historical_decrypt aws_kms_rewrap aws_kms_credential_values_recorded aws_kms_key_ids_recorded aws_kms_fresh_host_sha256 private_dr_restore_acceptance private_dr_http_up private_dr_http_ready private_dr_historical_decrypt private_dr_database_counts private_dr_acceptance_sha256 private_dr_provenance private_dr_snapshot_role private_dr_source_type private_dr_source_release_version private_dr_target_release_version private_dr_production_authority_confirmed private_dr_source_equals_runtime_database private_dr_provenance_sha256 production_database_prepare production_database_live_contract production_database_expected_name production_database_name production_database_stable_name_contract production_database_prepare_sha256 production_database_contract_sha256 production_database_url_recorded production_database_credential_values_recorded].each do |field|
      assert_includes metadata, field
    end
    refute_includes metadata, "DATABASE_URL"
    refute_includes metadata, "REDIS_URL"
    refute_includes metadata, "SECRET_KEY_BASE"
  end
  test "post-promotion evidence command is verification-only for app state" do
    script = Rails.root.join("script/release-postpromote-evidence").read
    assert_includes script, "RELEASE_PHASE=promoted"
    assert_includes script, "OFFHOST_ROUNDTRIP_STATUS=pass"
    assert_includes script, "POSTPROMOTE_EVIDENCE=PASS"
    assert_includes script, "sealed-source-integrity"
    assert_includes script, "SEALED_SOURCE_POSTPROMOTE=PASS"
    assert_includes script, "production-database-contract"
    assert_includes script, "PRODUCTION-DATABASE-CONTRACT.json"
    assert_includes script, "PRODUCTION_DATABASE_POSTPROMOTE=PASS"
    refute_includes script, "ln -sfn"
    refute_includes script, "tmux respawn-window"
    refute_includes script, "rails server"
  end

  test "operator checklist is generated from release metadata" do
    script = Rails.root.join("script/release-checklist").read
    assert_includes script, "RELEASE-METADATA.json"
    assert_includes script, "Operator Release Checklist"
    assert_includes script, "promotion_performed"
    assert_includes script, "offhost_roundtrip"
    assert_includes script, "public_package_integrity"
    assert_includes script, "public_package_links_checked"
    assert_includes script, "sealed_source_integrity"
    assert_includes script, "sealed_source_manifest_sha256"
    assert_includes script, "new_host_recovery"
    assert_includes script, "new_host_recovery_summary_sha256"
    assert_includes script, "aws_kms_fresh_host_rehearsal"
    assert_includes script, "aws_kms_live_ready"
    assert_includes script, "aws_kms_live_smoke"
    assert_includes script, "aws_kms_historical_decrypt"
    assert_includes script, "aws_kms_rewrap"
    assert_includes script, "aws_kms_fresh_host_sha256"
    assert_includes script, "ux_accessibility_preflight"
    assert_includes script, "ux_accessibility_manual_status"
    assert_includes script, "ux_accessibility_wcag_conformance_claimed"
    assert_includes script, "ux_accessibility_preflight_sha256"
    assert_includes script, "http_security_preflight"
    assert_includes script, "http_security_secret_values_absent"
    assert_includes script, "http_security_preflight_sha256"
    assert_includes script, "production_error_preflight"
    assert_includes script, "production_error_request_id_correlation"
    assert_includes script, "production_error_secret_values_absent"
    assert_includes script, "production_error_preflight_sha256"
    assert_includes script, "logging_redaction_preflight"
    assert_includes script, "logging_redaction_request_id_correlation"
    assert_includes script, "logging_redaction_secret_values_absent"
    assert_includes script, "logging_redaction_preflight_sha256"
    assert_includes script, "csrf_origin_preflight"
    assert_includes script, "csrf_origin_check_enabled"
    assert_includes script, "csrf_secret_values_absent"
    assert_includes script, "csrf_origin_preflight_sha256"
    assert_includes script, "rate_limit_preflight"
    assert_includes script, "rate_limit_cache_control_no_store"
    assert_includes script, "rate_limit_secret_values_absent"
    assert_includes script, "rate_limit_preflight_sha256"
    assert_includes script, "session_lifecycle_preflight"
    assert_includes script, "session_reauthentication_rotation"
    assert_includes script, "session_secret_values_absent"
    assert_includes script, "session_lifecycle_preflight_sha256"
    assert_includes script, "upgrade_from_fix46_preflight"
    assert_includes script, "upgrade_db_migrate_idempotent"
    assert_includes script, "upgrade_preflight_sha256"
  end
  test "release history preserves legacy versus metadata-native provenance" do
    script = Rails.root.join("script/release-history").read
    assert_includes script, '"evidence_model": "metadata-native"'
    assert_includes script, '"evidence_model": "legacy-evidence"'
    assert_includes script, '"legacy_without_metadata": True'
    assert_includes script, "FIX28_OFFHOST_ROUNDTRIP=PASS"
    assert_includes script, "RELEASE-METADATA.json"
    assert_includes script, "rev015-final-release-artifacts"
    assert_includes script, "rev016-final-release-artifacts"
  end
  test "public release history strips operational paths" do
    script = Rails.root.join("script/release-history-public").read
    assert_includes script, "Public Release History"
    assert_includes script, "legacy-evidence"
    assert_includes script, "/kaggle/"
    assert_includes script, "/mnt/workspace/"
    assert_includes script, "public history leak"
    assert_includes script, "RELEASE_ARTIFACT_DIR"
    assert_includes script, "accepted release output must remain outside source tree"
  end
  test "public portfolio index references the complete synthetic screenshot set" do
    index = Rails.root.join("docs/PUBLIC-PORTFOLIO-INDEX-FIX33.md").read
    (1..10).each do |number|
      assert_includes index, format("screenshots/%02d-", number)
    end
    assert_includes index, "ARCHITECTURE-OVERVIEW-FIX33.md"
    assert_includes index, "PUBLIC-RELEASE-HISTORY.md"
  end

  test "architecture overview preserves established trust boundary" do
    doc = Rails.root.join("docs/ARCHITECTURE-OVERVIEW-FIX33.md").read
    assert_includes doc, "AES-256-GCM"
    assert_includes doc, "fresh random 256-bit DEK"
    assert_includes doc, "not a zero-knowledge design"
    assert_includes doc, "PROMOTION_REQUIRED=yes"
  end
  test "documentation link validator covers local docs and screenshot references" do
    script = Rails.root.join("script/doc-link-check").read
    assert_includes script, "DOC_LINK_CHECK=PASS"
    assert_includes script, "DOC_SCREENSHOT_DIR"
    assert_includes script, "screenshots/"
  end

  test "public landing exposes stable portfolio metrics and evidence navigation" do
    doc = Rails.root.join("docs/PUBLIC-PORTFOLIO-LANDING-FIX34.md").read
    assert_includes doc, "5 purpose-built secret flows"
    assert_includes doc, "10 synthetic showcase screenshots"
    assert_includes doc, "4 canonical release artifacts"
    assert_includes doc, "PROMOTION_REQUIRED=yes"
    assert_includes doc, "PUBLIC-RELEASE-HISTORY.md"
  end
  test "release verification includes documentation link validation" do
    verifier = Rails.root.join("script/release-verify").read
    assert_includes verifier, 'run "documentation links" ./script/doc-link-check'
  end

  test "public showcase build validates staged package before archiving" do
    builder = Rails.root.join("script/build-public-showcase").read
    validator = Rails.root.join("script/public-showcase-validate").read
    assert_includes builder, "script/public-showcase-validate"
    %w[
      docs/DEV-0.1.5-PORTABILITY-MILESTONE-2026-10-02.md
      docs/DEV-0.1.5-PRODUCT-UX-MILESTONE-2026-10-02.md
      docs/DEV-0.1.5-SECURITY-WORKSPACE-UX-MILESTONE-2026-10-02.md
      docs/ROADMAP-0.1.4.md
      docs/OPERATOR-WORKFLOW-0.1.4.md
      docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.4.md
      docs/KEY-PROVIDER-CONTRACT-0.1.4.md
      docs/EXTERNAL-KMS-ADAPTER-CONTRACT-0.1.4.md
      docs/ROADMAP-0.1.6.md
      docs/OPERATOR-WORKFLOW-0.1.6.md
      docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.6.md
      docs/DEV-0.1.6-MILESTONE-1-RELEASE-TRUTH-2026-10-03.md
      docs/DEV-0.1.6-MILESTONE-3-AWS-KMS-AUTHORITY-AUDIT-2026-10-03.md
      docs/DEV-0.1.6-MILESTONE-4-KMS-ROLLBACK-HARDENING-2026-10-03.md
      docs/DEV-0.1.6-MILESTONE-5-KMS-OPERATOR-DIAGNOSTICS-2026-10-03.md
      docs/DEV-0.1.6-MILESTONE-6-AWS-KMS-FRESH-HOST-REHEARSAL-2026-10-03.md
    ].each { |doc| assert_includes builder, doc }
    assert_includes builder, "0.1.6-RELEASE-NOTES.md"
    assert_includes builder, "0.1.6.1-RELEASE-NOTES.md"
    assert_includes validator, "PUBLIC_SHOWCASE_VALIDATE=PASS"
    assert_includes validator, "expected 10 screenshots"
    assert_includes validator, "path escapes package"
  end
  test "public showcase validator verifies embedded checksums and screenshot manifest" do
    validator = Rails.root.join("script/public-showcase-validate").read
    assert_includes validator, "screenshot SHA256SUMS coverage mismatch"
    assert_includes validator, "MANIFEST.tsv coverage mismatch"
    assert_includes validator, "png_dimensions"
    assert_includes validator, "root SHA256SUMS coverage mismatch"
    assert_includes validator, "root checksum mismatch"
  end

  test "sealed source integrity script creates and verifies immutable source evidence" do
    script = Rails.root.join("script/sealed-source-integrity").read
    assert_includes script, "SEALED_SOURCE_MANIFEST=PASS"
    assert_includes script, "SEALED_SOURCE_INTEGRITY=PASS"
    assert_includes script, "SEALED_SOURCE_INTEGRITY=FAIL"
    assert_includes script, "public/assets-dev"
    assert_includes script, ".env."
  end

  test "FIX41 production HTTP security preflight verifies live response hardening without retaining cookie values" do
    script = Rails.root.join("script/production-http-security-preflight").read
    production = Rails.root.join("config/environments/production.rb").read

    assert_includes script, "HTTP_SECURITY_PREFLIGHT=PASS"
    assert_includes script, "HTTP_SECURITY_SECRET_VALUES=ABSENT"
    assert_includes script, "ASSUME_SSL=false"
    assert_includes script, "content-security-policy"
    assert_includes script, "strict-transport-security"
    assert_includes script, "samesite=strict"
    assert_includes script, "contains_secret_values"
    refute_includes script, "set-cookie:"
    assert_includes production, 'ENV.fetch("ASSUME_SSL", config.force_ssl.to_s)'
  end

  test "FIX40 UX accessibility preflight preserves automated versus human evidence boundary" do
    script = Rails.root.join("script/production-ux-accessibility-preflight").read
    doc = Rails.root.join("docs/PRODUCTION-UX-ACCESSIBILITY-ACCEPTANCE-FIX40.md").read
    matrix = Rails.root.join("docs/ACCESSIBILITY-MANUAL-EVIDENCE-FIX40.md").read

    assert_includes script, "UX_ACCESSIBILITY_PREFLIGHT=PASS"
    assert_includes script, "UX_ACCESSIBILITY_MANUAL_STATUS=PENDING"
    assert_includes script, '"wcag_conformance": False'
    assert_includes script, '"manual_accessibility_complete": False'
    assert_includes script, "production_ux_accessibility_test.rb"
    assert_includes doc, "does not claim formal WCAG conformance"
    assert_includes matrix, "PENDING HUMAN"
  end

  test "new host acceptance gate isolates recovery and preserves live current" do
    script = Rails.root.join("script/new-host-acceptance").read
    assert_includes script, "NEW_HOST_ACCEPTANCE_GATE=PASS"
    assert_includes script, "restore-new-host"
    assert_includes script, "before_current"
    assert_includes script, "after_current"
    assert_includes script, "new-host acceptance changed live current"
    assert_includes script, "NEW-HOST-RECOVERY-SUMMARY.json"
    assert_includes script, 'runtime_root="${NEW_HOST_RUNTIME_ROOT:-$tmp/runtime}"'
    assert_includes script, 'NEW_HOST_RUNTIME_ROOT="$runtime_root"'
    assert_includes script, 'chmod 711 "$tmp"'
    assert_includes script, "env -u ENV_FILE -u RUNTIME_ROOT"
    refute_includes script, 'RUNTIME_ROOT="${NEW_HOST_RUNTIME_ROOT:-${RUNTIME_ROOT:-}}"'
  end

  test "new host recovery orchestrator preserves portable recovery contract" do
    script = Rails.root.join("script/restore-new-host").read
    %w[BUNDLE_SIDECAR_VERIFY BUNDLE_INTERNAL_VERIFY SOURCE_RESTORE SECRET_RESTORE EXECUTABLE_REPAIR PROJECT_DOCTOR RAILS_START_MODE RAILS_PROCESS_VERIFY HEALTH NEW_HOST_SUMMARY NEW_HOST_ACCEPTANCE].each do |token|
      assert_includes script, token
    end
    assert_includes script, "NEW_HOST_BOOTSTRAP_MODE"
    assert_includes script, "NEW_HOST_PORT"
    assert_includes script, "NEW-HOST-RECOVERY-SUMMARY.json"
    assert_includes script, "database_reused"
    assert_includes script, "default_install_root()"
    assert_includes script, "/content/ruby-envelope-vault"
    assert_includes script, "XDG_DATA_HOME"
    assert_includes script, "RAILS_START_MODE=nohup"
    assert_includes script, "source ./activate-runtime.sh"
    assert_includes script, "NEW_HOST_AWS_SECRET_FILE"
    assert_includes script, "NEW_HOST_FIX_SECRET_MODE"
    assert_includes script, "script/prepare-secret-env"
    assert_includes script, "script/aws-kms-secret-preflight"
    assert_includes script, "AWS_SECRET_INTAKE=PASS"
    assert_includes script, "RECOVERED_KEY_PROVIDER"
    refute_includes script, "SECRET_KEY_BASE"
    refute_includes script, "DATABASE_URL"
    refute_includes script, "REDIS_URL"
  end

  test "migration bundle emits and verifies outer SHA256 sidecar" do
    script = Rails.root.join("script/build-migration-bundle").read

    assert_includes script, 'rm -f "$out" "$out.sha256"'
    assert_includes script, 'sha256sum "$(basename "$out")" > "$(basename "$out").sha256"'
    assert_includes script, 'sha256sum -c "$(basename "$out.sha256")"'
    assert_includes script, 'chmod 600 "$out.sha256"'
    assert_includes script, "BUNDLE_SIDECAR_VERIFY=PASS"
  end

  test "migration bundle builder discovers portable secrets root or requires explicit override" do
    script = Rails.root.join("script/build-current-migration-bundle").read

    assert_includes script, "REV_SECRETS_ROOT"
    assert_includes script, "/kaggle/working/ruby-envelope-vault-persistent/secrets"
    assert_includes script, '"$ROOT/../ruby-envelope-vault-secrets"'
    assert_includes script, "set REV_SECRETS_ROOT"
    refute_includes script, "REV_SECRETS_ROOT:-/mnt/workspace/ruby-envelope-vault-secrets"
    refute_includes script, "PRIVATE-DR-BUNDLE"
    refute_includes script, "0.1.4"
  end

  test "public showcase validator emits external machine-readable integrity evidence" do
    validator = Rails.root.join("script/public-showcase-validate").read
    builder = Rails.root.join("script/build-public-showcase").read

    assert_includes validator, "PUBLIC_PACKAGE_INTEGRITY_JSON=PASS"
    assert_includes validator, '"screenshot_checksum_status": "pass"'
    assert_includes validator, '"manifest_dimensions_status": "pass"'
    assert_includes validator, '"root_checksum_status": "pass"'
    assert_includes builder, "PUBLIC_PACKAGE_INTEGRITY_OUT"
  end
  test "FIX42 production failure handling preflight proves safe branded errors and correlation" do
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
  test "FIX43 production logging redaction preflight proves sensitive request values are filtered" do
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
  test "FIX44 CSRF origin preflight proves same-origin acceptance and cross-site rejection" do
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
  test "FIX45 production rate-limit preflight proves abuse controls and stateless 429 handling" do
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
  test "FIX46 production session lifecycle preflight proves rotation revocation and timeout behavior" do
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

  test "0.1.3 upgrade consolidation preflight preserves FIX46 database contract" do
    script = Rails.root.join("script/upgrade-from-fix46-preflight").read
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

  test "0.1.7 production boot checks are provider aware and validate AWS KMS registry authority" do
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

  test "0.1.7 operator readiness paths enforce AWS KMS active registry guard without printing key ids" do
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

  test "0.1.6 key provider diagnostics expose only safe operator fields" do
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

  test "0.1.6 fresh-host KMS rehearsal preserves live-evidence boundary and secret redaction" do
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

  test "0.1.6 live AWS KMS scripts bootstrap Bundler explicitly" do
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
    assert_includes script, "POSTPROMOTE_SOURCE_AND_DB_VERIFY=PASS"
    assert_includes script, '"$HOTFIX_ROOT/script/rebuild-production-env"'
    assert_includes script, '--release-root "$rc_dst"'
    refute_includes script, '"$rc_dst/script/rebuild-production-env"'
    assert_includes script, 'bootstrap.sh" setup'
    assert_includes script, "POSTPROMOTE_DATABASE_RESTORE=PASS"
    assert_includes script, "--repoint-current"
    assert_includes script, "--start-production"
    assert_includes script, 'if [[ "$repoint" == "1" ]]'
    assert_includes script, 'if [[ "$start_production" == "1" ]]'
    assert_includes script, "start-requires-repoint"
  end
end
