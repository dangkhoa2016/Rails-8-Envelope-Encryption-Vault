require "test_helper"
require "json"
require "open3"
require "tmpdir"

class ProductionDatabaseContractTest < ActiveSupport::TestCase
  NAME_SCRIPT = Rails.root.join("script/production-database-name")
  CONTRACT_SCRIPT = Rails.root.join("script/production-database-contract")

  test "stable database name is deterministic across dev and release versions" do
    assert_equal "ruby_envelope_vault_production_v0_1_8", run_name("0.1.8-dev")
    assert_equal "ruby_envelope_vault_production_v0_1_8", run_name("0.1.8")
    assert_equal "ruby_envelope_vault_production_v0_1_7", run_name("0.1.7")
  end

  test "unsupported version cannot produce a production database name" do
    _stdout, stderr, status = Open3.capture3(NAME_SCRIPT.to_s, "dev-latest")

    refute status.success?
    assert_includes stderr, "unsupported-version"
  end

  test "production database contract accepts exact stable database name without recording url" do
    Dir.mktmpdir do |dir|
      env_file = File.join(dir, "production.env")
      evidence = File.join(dir, "evidence.json")
      stable_name = run_name(Rails.root.join("VERSION").read.strip)
      File.write(env_file, "DATABASE_URL=postgresql://user:do-not-print@127.0.0.1:5432/#{stable_name}\n")
      File.chmod(0o600, env_file)

      stdout, stderr, status = Open3.capture3(
        {
          "PRODUCTION_ENV_FILE" => env_file,
          "PRODUCTION_DATABASE_EVIDENCE_OUT" => evidence
        },
        CONTRACT_SCRIPT.to_s
      )

      assert status.success?, stderr
      assert_includes stdout, "PRODUCTION_DATABASE_CONTRACT=PASS"
      refute_includes stdout, "do-not-print"
      refute_includes stderr, "do-not-print"

      data = JSON.parse(File.read(evidence))
      assert_equal "pass", data["status"]
      assert_equal stable_name, data["database_name"]
      assert_equal false, data["database_url_recorded"]
      assert_equal false, data["credential_values_recorded"]
      assert_equal false, data["contains_secret_values"]
    end
  end

  test "production database contract rejects a temporary acceptance database" do
    Dir.mktmpdir do |dir|
      env_file = File.join(dir, "production.env")
      File.write(env_file, "DATABASE_URL=postgresql://user:do-not-print@127.0.0.1:5432/ruby_envelope_vault_dr_accept_123\n")
      File.chmod(0o600, env_file)

      _stdout, stderr, status = Open3.capture3(
        { "PRODUCTION_ENV_FILE" => env_file },
        CONTRACT_SCRIPT.to_s
      )

      refute status.success?
      assert_includes stderr, "database-name-mismatch"
      refute_includes stderr, "do-not-print"
    end
  end

  test "production startup enforces stable database naming by default and isolated mode is explicit" do
    script = Rails.root.join("script/start-production").read
    acceptance = Rails.root.join("script/private-dr-restore-acceptance").read

    assert_includes script, "PRODUCTION_DATABASE_CONTRACT_MODE:-stable"
    assert_includes script, '"$ROOT/script/production-database-contract"'
    assert_includes script, "PRODUCTION_DATABASE_CONTRACT=SKIP mode=isolated"
    assert_includes acceptance, "PRODUCTION_DATABASE_CONTRACT_MODE=isolated"
  end

  test "private dr keep-db preserves only after complete acceptance" do
    script = Rails.root.join("script/private-dr-restore-acceptance").read

    assert_includes script, "preserve_db=0"
    assert_includes script, 'db_created" == "1" && "$preserve_db" != "1"'
    assert_includes script, "preserve_db=1"
    assert_operator script.index("PRIVATE_DR_ACCEPTANCE=PASS"), :<, script.index("preserve_db=1")
  end

  test "production database preparation restores directly into deterministic stable name" do
    script = Rails.root.join("script/prepare-production-database").read

    assert_includes script, "script/production-database-name"
    assert_includes script, '--database-name "$stable_db"'
    assert_includes script, "--keep-db"
    assert_includes script, "private-dr-provenance-preflight"
    assert_includes script, "PRODUCTION-DATABASE-PREPARE.json"
    assert_includes script, "stable-database-already-exists"
    assert_includes script, "--replace"
    assert_includes script, 'dropdb" -h "$pg_socket"'
    assert_includes script, 'prepared" == "1" && "$complete" != "1"'
    assert_includes script, 'PRIVATE_DR_RUNTIME_ENV_FILE="$runtime_env"'
  end

  test "release promotion preparation is verification only for current symlink" do
    script = Rails.root.join("script/release-prepare-promotion").read

    assert_includes script, "phase"
    assert_includes script, "prepromote"
    assert_includes script, "prepare-production-database"
    assert_includes script, "PRODUCTION-DATABASE-PREPARE.json"
    assert_includes script, "PROMOTION_REPOINT_ALLOWED=yes"
    refute_includes script, "ln -sfn"
    refute_includes script, "rails server"
  end

  test "postpromotion evidence revalidates live stable database contract" do
    script = Rails.root.join("script/release-postpromote-evidence").read

    assert_includes script, "production-database-contract"
    assert_includes script, "PRODUCTION-DATABASE-CONTRACT.json"
    assert_includes script, "PRODUCTION_DATABASE_POSTPROMOTE=PASS"
  end

  private

  def run_name(version)
    stdout, stderr, status = Open3.capture3(NAME_SCRIPT.to_s, version)
    assert status.success?, stderr
    stdout.strip
  end
end
