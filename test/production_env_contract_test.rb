require "test_helper"
require "open3"
require "tmpdir"

class ProductionEnvContractTest < ActiveSupport::TestCase
  LIB = Rails.root.join("script/lib/production-env.sh").to_s

  test "explicit production env path wins without exposing file contents" do
    Dir.mktmpdir do |dir|
      env_file = File.join(dir, "production.env")
      File.write(env_file, "SECRET_KEY_BASE=never-print-this\n")
      File.chmod(0o600, env_file)

      stdout, stderr, status = Open3.capture3(
        { "PRODUCTION_ENV_FILE" => env_file },
        "bash", "-c", 'source "$1"; revault_production_env_path', "--", LIB
      )

      assert status.success?, stderr
      assert_equal env_file, stdout.strip
      refute_includes stdout, "never-print-this"
    end
  end

  test "runtime root default resolves outside source tree" do
    Dir.mktmpdir do |runtime_root|
      stdout, stderr, status = Open3.capture3(
        { "PRODUCTION_ENV_FILE" => nil, "OPS_ENV_FILE" => nil, "RUNTIME_ROOT" => runtime_root },
        "bash", "-c", 'source "$1"; revault_production_env_path', "--", LIB
      )

      assert status.success?, stderr
      assert_equal File.join(runtime_root, "production.env"), stdout.strip
    end
  end

  test "production env inside application source tree is rejected" do
    env_file = Rails.root.join("tmp/production-contract-inside.env")
    File.write(env_file, "DEMO_MODE=true\n")
    File.chmod(0o600, env_file)

    _stdout, stderr, status = Open3.capture3(
      "bash", "-c",
      'source "$1"; revault_validate_production_env_path "$2" "$3"',
      "--", LIB, Rails.root.to_s, env_file.to_s
    )

    refute status.success?
    assert_includes stderr, "outside the application source tree"
  ensure
    File.delete(env_file) if env_file&.exist?
  end

  test "production env with group or world permissions is rejected" do
    Dir.mktmpdir do |dir|
      env_file = File.join(dir, "production.env")
      File.write(env_file, "DEMO_MODE=true\n")
      File.chmod(0o644, env_file)

      _stdout, stderr, status = Open3.capture3(
        "bash", "-c",
        'source "$1"; revault_validate_production_env_path "$2" "$3"',
        "--", LIB, Rails.root.to_s, env_file
      )

      refute status.success?
      assert_includes stderr, "permissions must be 0600 or 0400"
    end
  end

  test "production startup does not fall back to development env files" do
    script = Rails.root.join("script/start-production").read

    assert_includes script, "export ENV_FILE=/dev/null"
    assert_includes script, "revault_load_production_env"
    assert_includes script, "PRODUCTION_ENV_SOURCE=external"
    refute_includes script, ".env.kaggle"
    refute_includes script, "source-env.kaggle"
  end


  test "fresh-host production env rebuild uses host-local runtime credentials without embedding aws credentials" do
    Dir.mktmpdir do |dir|
      runtime_env = File.join(dir, "runtime.env")
      aws_env = File.join(dir, "aws.env")
      output = File.join(dir, "production.env")
      base_env = File.join(dir, "base-production.env")
      File.write(runtime_env, <<~ENV)
        export DATABASE_URL=postgresql://vault_user:host-local-password@127.0.0.1:5432/ruby_envelope_vault_development
        export SECRET_KEY_BASE=#{"a" * 128}
      ENV
      File.write(base_env, <<~ENV)
        export APP_HOSTS=localhost,example.test
        export APP_URL=https://example.test
        export DEMO_MODE=false
        export FORCE_SSL=true
        export ALLOW_SIGNUPS=false
        export REQUIRE_MFA=true
        export REAUTH_ON_REVEAL=true
        export DATABASE_URL=postgresql://old_user:old_password@old-host:5432/old_db
        export SECRET_KEY_BASE=REPLACE_WITH_OLD_SECRET
        export VAULT_ACTIVE_KEK_ID=REPLACE_WITH_OLD_KEY
      ENV
      File.write(aws_env, <<~ENV)
        export AWS_ACCESS_KEY_ID=fake-access
        export AWS_SECRET_ACCESS_KEY=fake-secret
        export AWS_REGION=ap-southeast-1
        export AWS_KMS_KEY_ID=22222222-2222-2222-2222-222222222222
        export AWS_KMS_KEY01_ID=11111111-1111-1111-1111-111111111111
        export AWS_KMS_KEY02_ID=22222222-2222-2222-2222-222222222222
      ENV
      File.chmod(0o600, runtime_env)
      File.chmod(0o600, aws_env)
      File.chmod(0o600, base_env)

      stdout, stderr, status = Open3.capture3(
        Rails.root.join("script/rebuild-production-env").to_s,
        "--runtime-env", runtime_env,
        "--aws-secret", aws_env,
        "--base-production-env", base_env,
        "--output", output
      )

      assert status.success?, stderr
      assert_includes stdout, "REBUILD_PRODUCTION_ENV=PASS"
      body = File.read(output)
      assert_includes body, "ruby_envelope_vault_production_v0_1_8_1"
      assert_includes body, "VAULT_KEY_PROVIDER=aws_kms"
      assert_includes body, "22222222-2222-2222-2222-222222222222"
      assert_includes body, "#{"a" * 128}"
      assert_includes body, "APP_URL=https://example.test"
      assert_includes body, "FORCE_SSL=true"
      assert_includes body, "REQUIRE_MFA=true"
      refute_includes body, "old_user"
      refute_includes body, "old_password"
      refute_includes body, "REPLACE_WITH_OLD_SECRET"
      refute_includes body, "REPLACE_WITH_OLD_KEY"
      refute_includes body, "fake-access"
      refute_includes body, "fake-secret"
      assert_equal 0o600, File.stat(output).mode & 0o777
    end
  end


  test "production env rebuild can target an older restored release root" do
    Dir.mktmpdir do |dir|
      runtime_env = File.join(dir, "runtime.env")
      aws_env = File.join(dir, "aws.env")
      output = File.join(dir, "production.env")
      release_root = File.join(dir, "restored-release")
      script_dir = File.join(release_root, "script")
      FileUtils.mkdir_p(script_dir)

      File.write(runtime_env, <<~ENV)
        export DATABASE_URL=postgresql://vault_user:host-password@127.0.0.1:5432/dev_db
        export SECRET_KEY_BASE=#{"b" * 128}
      ENV
      File.write(aws_env, <<~ENV)
        export AWS_ACCESS_KEY_ID=fake-access
        export AWS_SECRET_ACCESS_KEY=fake-secret
        export AWS_REGION=ap-southeast-1
        export AWS_KMS_KEY_ID=22222222-2222-2222-2222-222222222222
        export AWS_KMS_KEY01_ID=11111111-1111-1111-1111-111111111111
        export AWS_KMS_KEY02_ID=22222222-2222-2222-2222-222222222222
      ENV
      File.write(File.join(script_dir, "production-database-name"), <<~SH)
        #!/usr/bin/env bash
        echo ruby_envelope_vault_production_v0_1_8
      SH
      File.write(File.join(script_dir, "production-database-contract"), <<~'SH')
        #!/usr/bin/env bash
        set -e
        source "$PRODUCTION_ENV_FILE"
        case "$DATABASE_URL" in
          */ruby_envelope_vault_production_v0_1_8) exit 0 ;;
          *) exit 2 ;;
        esac
      SH
      File.chmod(0o600, runtime_env)
      File.chmod(0o600, aws_env)
      File.chmod(0o755, File.join(script_dir, "production-database-name"))
      File.chmod(0o755, File.join(script_dir, "production-database-contract"))

      stdout, stderr, status = Open3.capture3(
        Rails.root.join("script/rebuild-production-env").to_s,
        "--runtime-env", runtime_env,
        "--aws-secret", aws_env,
        "--release-root", release_root,
        "--output", output
      )

      assert status.success?, stderr
      assert_includes stdout, "database_name=ruby_envelope_vault_production_v0_1_8"
      body = File.read(output)
      assert_includes body, "ruby_envelope_vault_production_v0_1_8"
      refute_includes body, "ruby_envelope_vault_production_v0_1_8_1"
    end
  end

  test "bootstrap start self-heals a missing bundle before building assets" do
    script = Rails.root.join("bootstrap.sh").read
    start_case = script.split('case "$COMMAND" in', 2).last

    assert_includes start_case, 'BUNDLE_PATH="$BUNDLE_DIR" bundle check'
    assert_includes start_case, "install_bundle"
    assert_operator start_case.index("bundle check"), :<, start_case.index("build_web_assets")
  end

  test "production operator diagnostics use shared resolver" do
    %w[script/key-provider-status script/operator-status].each do |path|
      script = Rails.root.join(path).read
      assert_includes script, "script/lib/production-env.sh"
      assert_includes script, "revault_production_env_path"
      assert_includes script, "revault_validate_production_env_path"
    end
  end
end
