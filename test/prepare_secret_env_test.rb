require "test_helper"
require "open3"
require "tmpdir"

class PrepareSecretEnvTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/prepare-secret-env").to_s

  test "normalizes CRLF to protected copy without leaking values" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "ruby-encrypt-env")
      output = File.join(dir, "normalized.env")
      secret = "never-print-this-secret"
      File.binwrite(input, "export AWS_ACCESS_KEY_ID=abc\r\nexport AWS_SECRET_ACCESS_KEY=#{secret}\r\n")
      File.chmod(0o644, input)

      stdout, stderr, status = Open3.capture3(
        { "REQUIRED_SECRET_VARS" => "AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY" },
        SCRIPT, input, output
      )

      assert status.success?, stderr
      assert_includes stdout, "SECRET_ENV_INPUT_MODE=644"
      assert_includes stdout, "SECRET_ENV_INPUT_MODE_RESTRICTED=no"
      assert_includes stdout, "SECRET_ENV_CRLF=yes"
      assert_includes stdout, "SECRET_ENV_OUTPUT_MODE=600"
      assert_includes stdout, "SECRET_ENV_STATUS=PASS"
      refute_includes stdout, secret
      refute_includes stderr, secret
      assert_equal 0o600, File.stat(output).mode & 0o777
      refute_includes File.binread(output), "\r"
      assert_includes File.binread(output), secret
    end
  end

  test "fix input mode explicitly enforces 0600" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "secret.env")
      File.write(input, "TOKEN=value\n")
      File.chmod(0o644, input)

      stdout, stderr, status = Open3.capture3(
        SCRIPT, "--fix-input-mode", "--check-only", input
      )

      assert status.success?, stderr
      assert_equal 0o600, File.stat(input).mode & 0o777
      assert_includes stdout, "SECRET_ENV_INPUT_MODE=600"
      assert_includes stdout, "SECRET_ENV_INPUT_MODE_RESTRICTED=yes"
    end
  end

  test "missing required variable fails safely" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "secret.env")
      File.write(input, "TOKEN=value\n")
      File.chmod(0o600, input)

      stdout, _stderr, status = Open3.capture3(
        { "REQUIRED_SECRET_VARS" => "TOKEN REQUIRED_TWO" },
        SCRIPT, "--check-only", input
      )

      refute status.success?
      assert_includes stdout, "SECRET_ENV_REQUIRED_TOKEN=present"
      assert_includes stdout, "SECRET_ENV_REQUIRED_REQUIRED_TWO=missing"
      assert_includes stdout, "SECRET_ENV_STATUS=FAIL reason=missing-required-variable"
      refute_includes stdout, "value"
    end
  end

  test "nul byte is rejected" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "secret.env")
      File.binwrite(input, "TOKEN=value\x00other\n")
      File.chmod(0o600, input)

      stdout, _stderr, status = Open3.capture3(SCRIPT, "--check-only", input)

      refute status.success?
      assert_includes stdout, "SECRET_ENV_NUL=yes"
      assert_includes stdout, "SECRET_ENV_STATUS=FAIL reason=nul-byte"
      refute_includes stdout, "other"
    end
  end

  test "rejects executable shell statements instead of copying them" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "secret.env")
      File.write(input, "TOKEN=value\ntouch /tmp/revault-should-not-run\n")
      File.chmod(0o600, input)

      stdout, _stderr, status = Open3.capture3(SCRIPT, "--check-only", input)

      refute status.success?
      assert_includes stdout, "SECRET_ENV_STATUS=FAIL reason=unsupported-env-line-2"
      refute File.exist?("/tmp/revault-should-not-run")
    end
  ensure
    File.delete("/tmp/revault-should-not-run") if File.exist?("/tmp/revault-should-not-run")
  end

  test "does not change permissions of an existing output parent directory" do
    Dir.mktmpdir do |dir|
      parent = File.join(dir, "existing")
      Dir.mkdir(parent, 0o755)
      input = File.join(dir, "secret.env")
      output = File.join(parent, "normalized.env")
      File.write(input, "TOKEN=value\n")
      File.chmod(0o600, input)

      _stdout, stderr, status = Open3.capture3(SCRIPT, input, output)

      assert status.success?, stderr
      assert_equal 0o755, File.stat(parent).mode & 0o777
      assert_equal 0o600, File.stat(output).mode & 0o777
    end
  end

  test "rewrites command substitution looking values as safe literals" do
    Dir.mktmpdir do |dir|
      input = File.join(dir, "secret.env")
      output = File.join(dir, "normalized.env")
      marker = "/tmp/revault-command-substitution-marker"
      File.write(input, %(TOKEN="$(touch #{marker})"\n))
      File.chmod(0o600, input)

      stdout, stderr, status = Open3.capture3(SCRIPT, input, output)

      assert status.success?, stderr
      assert_includes stdout, "SECRET_ENV_STATUS=PASS"
      refute File.exist?(marker)

      shell_stdout, shell_stderr, shell_status = Open3.capture3(
        "bash", "-c", 'set -eu; source "$1"; printf "%s" "$TOKEN"', "--", output
      )
      assert shell_status.success?, shell_stderr
      assert_equal "$(touch #{marker})", shell_stdout
      refute File.exist?(marker)
    ensure
      File.delete(marker) if File.exist?(marker)
    end
  end
end
