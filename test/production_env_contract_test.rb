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

  test "production operator diagnostics use shared resolver" do
    %w[script/key-provider-status script/operator-status].each do |path|
      script = Rails.root.join(path).read
      assert_includes script, "script/lib/production-env.sh"
      assert_includes script, "revault_production_env_path"
      assert_includes script, "revault_validate_production_env_path"
    end
  end
end
