require "test_helper"
require "open3"
require "tmpdir"

class PostpromoteRecoveryKeyCustodyTest < ActiveSupport::TestCase
  ROOT = Rails.root
  WRAP = ROOT.join("script/wrap-postpromote-recovery-key").to_s
  VERIFY = ROOT.join("script/verify-postpromote-recovery-set").to_s

  def run!(*args)
    stdout, stderr, status = Open3.capture3(*args)
    [ stdout, stderr, status ]
  end

  def with_fixture
    Dir.mktmpdir do |dir|
      fresh = File.join(dir, "fresh.agekey")
      baseline = File.join(dir, "baseline.agekey")
      recipient = File.join(dir, "baseline-recipient.txt")
      archive = File.join(dir, "bundle.tar.gz.age")
      out = File.join(dir, "set")

      _stdout, stderr, status = run!("age-keygen", "-o", fresh)
      assert status.success?, stderr
      File.chmod(0o600, fresh)

      _stdout, stderr, status = run!("age-keygen", "-o", baseline)
      assert status.success?, stderr
      File.chmod(0o600, baseline)
      _stdout, stderr, status = run!("age-keygen", "-y", baseline)
      assert status.success?, stderr
      public_key = _stdout.strip
      assert_match(/^age1/, public_key)
      File.write(recipient, "#{public_key}\n")

      File.binwrite(archive, "synthetic encrypted archive bytes")
      sha = Digest::SHA256.file(archive).hexdigest
      File.write("#{archive}.sha256", "#{sha}  #{File.basename(archive)}\n")

      yield dir, fresh, baseline, recipient, archive, out
    end
  end

  test "wrap helper creates sanitized recovery set without raw key" do
    with_fixture do |_dir, fresh, _baseline, recipient, archive, out|
      stdout, stderr, status = run!(WRAP,
        "--fresh-key", fresh,
        "--baseline-recipient-file", recipient,
        "--archive", archive,
        "--output-dir", out)

      assert status.success?, stderr
      assert_includes stdout, "RECOVERY_KEY_WRAP=PASS"
      refute File.exist?(File.join(out, File.basename(fresh)))

      evidence = JSON.parse(File.read(File.join(out, "RECOVERY-KEY-CUSTODY.json")))
      assert_equal "pass", evidence["status"]
      assert_equal false, evidence["raw_fresh_key_in_output"]
      assert_equal false, evidence["credential_values_recorded"]
      assert_equal false, evidence["private_key_contents_recorded"]
      assert_equal false, evidence["plaintext_recorded"]
      refute_includes File.read(File.join(out, "RECOVERY-KEY-CUSTODY.json")), File.read(fresh)
    end
  end

  test "verifier accepts complete untampered recovery set" do
    with_fixture do |_dir, fresh, _baseline, recipient, archive, out|
      _stdout, stderr, status = run!(WRAP,
        "--fresh-key", fresh,
        "--baseline-recipient-file", recipient,
        "--archive", archive,
        "--output-dir", out)
      assert status.success?, stderr

      stdout, stderr, status = run!(VERIFY,
        "--archive", archive,
        "--recovery-set-dir", out)

      assert status.success?, stderr
      assert_includes stdout, "RECOVERY_SET_VERIFY=PASS"
      assert_includes stdout, "RECOVERY_SET_RAW_FRESH_KEY_ABSENT=PASS"
    end
  end

  test "verifier rejects tampered wrapped key" do
    with_fixture do |_dir, fresh, _baseline, recipient, archive, out|
      _stdout, stderr, status = run!(WRAP,
        "--fresh-key", fresh,
        "--baseline-recipient-file", recipient,
        "--archive", archive,
        "--output-dir", out)
      assert status.success?, stderr

      wrapped = Dir[File.join(out, "*.agekey.age")].first
      File.open(wrapped, "ab") { |f| f.write("tamper") }

      _stdout, stderr, status = run!(VERIFY,
        "--archive", archive,
        "--recovery-set-dir", out)

      refute status.success?
      assert_includes stderr, "reason=wrapped-key-sha256-mismatch"
    end
  end

  test "wrap helper rejects unsafe fresh key mode" do
    with_fixture do |_dir, fresh, _baseline, recipient, archive, out|
      File.chmod(0o644, fresh)
      _stdout, stderr, status = run!(WRAP,
        "--fresh-key", fresh,
        "--baseline-recipient-file", recipient,
        "--archive", archive,
        "--output-dir", out)

      refute status.success?
      assert_includes stderr, "reason=unsafe-fresh-key-mode"
    end
  end
end
