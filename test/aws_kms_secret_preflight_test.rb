require "test_helper"
require "open3"
require "tmpdir"

class AwsKmsSecretPreflightTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/aws-kms-secret-preflight").to_s

  def write_env(path, active: "key-02", mode: 0o600)
    File.write(path, <<~ENV)
      export AWS_ACCESS_KEY_ID=access-value
      export AWS_SECRET_ACCESS_KEY=secret-value
      export AWS_REGION=ap-southeast-1
      export AWS_KMS_KEY_ID=#{active}
      export AWS_KMS_KEY01_ID=key-01
      export AWS_KMS_KEY02_ID=key-02
    ENV
    File.chmod(mode, path)
  end

  test "passes normalized active alias without printing credential values" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "aws.env")
      write_env(path)

      stdout, stderr, status = Open3.capture3(SCRIPT, path)

      assert status.success?, stderr
      assert_includes stdout, "AWS_KMS_ACTIVE_ALIAS_MATCHES_KEY02=yes"
      assert_includes stdout, "AWS_KMS_ACTIVE_ALIAS_DIFFERS_KEY01=yes"
      assert_includes stdout, "AWS_KMS_SECRET_STATUS=PASS"
      refute_includes stdout, "access-value"
      refute_includes stdout, "secret-value"
      refute_includes stdout, "key-01"
      refute_includes stdout, "key-02"
    end
  end

  test "fails stale active alias safely" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "aws.env")
      write_env(path, active: "key-01")

      stdout, _stderr, status = Open3.capture3(SCRIPT, path)

      refute status.success?
      assert_includes stdout, "AWS_KMS_ACTIVE_ALIAS_MATCHES_KEY02=no"
      assert_includes stdout, "AWS_KMS_ACTIVE_ALIAS_DIFFERS_KEY01=no"
      assert_includes stdout, "AWS_KMS_SECRET_STATUS=FAIL reason=active-alias-drift"
      refute_includes stdout, "key-01"
      refute_includes stdout, "key-02"
    end
  end

  test "fails unsafe mode" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "aws.env")
      write_env(path, mode: 0o644)

      stdout, _stderr, status = Open3.capture3(SCRIPT, path)

      refute status.success?
      assert_includes stdout, "AWS_KMS_SECRET_MODE_RESTRICTED=no"
      assert_includes stdout, "AWS_KMS_SECRET_STATUS=FAIL reason=unsafe-mode"
    end
  end
end
