require "test_helper"

class PrivateDrRestoreAcceptanceTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/private-dr-restore-acceptance")

  test "orchestrator requires encrypted archive recovery key and aws secret" do
    script = SCRIPT.read

    assert_includes script, "--archive"
    assert_includes script, "--outer-key"
    assert_includes script, "--aws-secret"
    assert_includes script, "absolute-path-required"
  end

  test "runtime env may be supplied externally for source-only release candidates" do
    script = SCRIPT.read

    assert_includes script, 'runtime_env="${PRIVATE_DR_RUNTIME_ENV_FILE:-${ENV_FILE:-$ROOT/.env.kaggle}}"'
    assert_includes script, "runtime-env-unavailable"
    assert_includes script, 'source "$runtime_env"'
    assert_includes script, 'ENV_FILE="$runtime_env" "$ROOT/bootstrap.sh" start'
    refute_includes script, 'ENV_FILE="$ROOT/.env.kaggle"'
  end

  test "aws secret preflight occurs before outer dr decrypt" do
    script = SCRIPT.read

    preflight = script.index('"$ROOT/script/aws-kms-secret-preflight" "$normalized_aws"')
    decrypt = script.index('age -d -i "$outer_key"')

    assert preflight
    assert decrypt
    assert_operator preflight, :<, decrypt
  end

  test "restore creates isolated database owned by app role and restores through target url" do
    script = SCRIPT.read

    assert_includes script, 'db_name="ruby_envelope_vault_dr_accept_'
    assert_includes script, '-O "$app_user" "$db_name"'
    assert_includes script, 'TARGET_DATABASE_URL="$target_database_url" "$ROOT/script/restore-db"'
    refute_includes script, 'TARGET_DATABASE_URL="$DATABASE_URL"'
  end

  test "cleanup removes staging and isolated database by default" do
    script = SCRIPT.read

    assert_includes script, "trap cleanup EXIT"
    assert_includes script, 'dropdb" -h "$pg_socket"'
    assert_includes script, "--force"
    assert_includes script, 'rm -rf "$stage"'
    assert_includes script, "--keep-db"
    assert_includes script, "--database-name"
    assert_includes script, "preserve_db=0"
    assert_includes script, "preserve_db=1"
    assert_includes script, 'kill -KILL "$server_pid"'
    assert_includes script, 'wait "$server_pid"'
    assert_includes script, 'server_pidfile="$ROOT/tmp/pids/server-$port.pid"'
    assert_includes script, '[[ "$pidfile_pid" == "$server_pid" ]] && rm -f "$server_pidfile"'
    assert_operator script.index('kill "$server_pid"'), :<, script.index('kill -KILL "$server_pid"')
  end

  test "acceptance verifies historical decrypt and production readiness" do
    script = SCRIPT.read

    assert_includes script, "PRIVATE_DR_HISTORICAL_DECRYPT=PASS"
    assert_includes script, "Vault::RevealItem.call"
    assert_includes script, "PRIVATE_DR_UP=200"
    assert_includes script, "PRIVATE_DR_READY=200"
    assert_includes script, "script/start-production"
  end

  test "evidence explicitly records no credential key-id or plaintext values" do
    script = SCRIPT.read

    assert_includes script, '"credential_values_recorded": False'
    assert_includes script, '"key_ids_recorded": False'
    assert_includes script, '"plaintext_recorded": False'
    assert_includes script, "PRIVATE_DR_EVIDENCE=PASS"
    refute_includes script, "puts payload"
  end
end
