require "test_helper"
require "open3"
require "tmpdir"

class OffsitePostpromoteRecoveryAcceptanceTest < ActiveSupport::TestCase
  ROOT = Rails.root
  BUILDER = ROOT.join("script/build-postpromote-full-private").to_s
  ACCEPT = ROOT.join("script/offsite-postpromote-recovery-acceptance").to_s

  def run!(env, *args)
    stdout, stderr, status = Open3.capture3(env, *args)
    [ stdout, stderr, status ]
  end

  def make_repo(path, version, branch)
    Dir.mkdir(path)
    File.write(File.join(path, "VERSION"), "#{version}\n")
    system("git", "-C", path, "init", "-q")
    system("git", "-C", path, "config", "user.email", "test@example.invalid")
    system("git", "-C", path, "config", "user.name", "Test")
    system("git", "-C", path, "checkout", "-q", "-b", branch)
    system("git", "-C", path, "add", "VERSION")
    system("git", "-C", path, "commit", "-q", "-m", "fixture")
  end

  def with_bundle
    Dir.mktmpdir do |dir|
      dev = File.join(dir, "DEV-0.1.8.3")
      rc = File.join(dir, "RC-0.1.8.2")
      rollback = File.join(dir, "RC-0.1.8.1")
      authority = File.join(dir, "authority")
      artifacts = File.join(dir, "artifacts")
      dump = File.join(dir, "production.dump")
      baseline_key = File.join(dir, "baseline.agekey")
      recipient = File.join(dir, "recipient.txt")
      output = File.join(dir, "output")
      remote = File.join(dir, "remote")
      evidence = File.join(dir, "evidence.json")
      fake_bin = File.join(dir, "bin")

      make_repo(dev, "0.1.8.3-dev", "dev-0.1.8.3")
      make_repo(rc, "0.1.8.2", "rc-0.1.8.2")
      make_repo(rollback, "0.1.8.1", "rc-0.1.8.1")
      Dir.mkdir(authority)
      File.write(File.join(authority, "authority.txt"), "synthetic")
      Dir.mkdir(artifacts)
      File.write(File.join(artifacts, "RELEASE-METADATA.json"), JSON.pretty_generate(
        "release_version" => "0.1.8.2", "phase" => "promoted",
        "promotion_performed" => true, "release_verify" => "pass",
        "sealed_source_integrity" => "pass", "offhost_roundtrip" => "pass"
      ))
      File.binwrite(dump, "synthetic database dump")

      _out, err, st = run!({}, "age-keygen", "-o", baseline_key)
      assert st.success?, err
      File.chmod(0o600, baseline_key)
      out, err, st = run!({}, "age-keygen", "-y", baseline_key)
      assert st.success?, err
      File.write(recipient, out)

      _out, err, st = run!(
        {},
        BUILDER,
        "--dev-root", dev, "--rc-root", rc, "--rollback-root", rollback,
        "--private-authority", authority, "--release-artifacts", artifacts,
        "--database-dump", dump, "--baseline-recipient-file", recipient,
        "--output-dir", output, "--bundle-name", "fixture-full-private"
      )
      assert st.success?, err

      Dir.mkdir(fake_bin)
      fake_pg_restore = File.join(fake_bin, "pg_restore")
      File.write(fake_pg_restore, "#!/usr/bin/env bash\nexit 0\n")
      File.chmod(0o755, fake_pg_restore)

      yield output, baseline_key, remote, evidence, fake_bin
    end
  end

  test "filesystem driver performs full recovery chain" do
    with_bundle do |output, baseline_key, remote, evidence, fake_bin|
      archive = File.join(output, "fixture-full-private.tar.gz.age")
      set_dir = File.join(output, "fixture-full-private-RECOVERY-SET")
      env = { "PATH" => "#{fake_bin}:#{ENV.fetch('PATH')}" }

      stdout, stderr, status = run!(
        env,
        ACCEPT,
        "--archive", archive,
        "--recovery-set-dir", set_dir,
        "--baseline-key", baseline_key,
        "--driver", "filesystem",
        "--dest", remote,
        "--evidence", evidence
      )

      assert status.success?, stderr
      %w[
        OFFSITE_RECOVERY_LOCAL_SET_VERIFY=PASS
        OFFSITE_RECOVERY_UPLOAD=PASS
        OFFSITE_RECOVERY_DOWNLOAD=PASS
        OFFSITE_RECOVERY_ARCHIVE_SHA256=PASS
        OFFSITE_RECOVERY_WRAPPED_KEY_SHA256=PASS
        OFFSITE_RECOVERY_FRESH_KEY=PASS
        OFFSITE_RECOVERY_INTERNAL_MANIFEST=PASS
        OFFSITE_RECOVERY_GIT_FSCK=PASS
        OFFSITE_RECOVERY_DATABASE_CATALOG=PASS
        OFFSITE_RECOVERY_PROMOTED_METADATA=PASS
        OFFSITE_RECOVERY_ACCEPTANCE=PASS
      ].each { |token| assert_includes stdout, token }

      data = JSON.parse(File.read(evidence))
      assert_equal "pass", data["status"]
      assert_equal "filesystem", data["driver"]
      assert_equal false, data["remote_destination_recorded"]
      assert_equal false, data["credential_values_recorded"]
      assert_equal false, data["private_key_contents_recorded"]
      assert_equal false, data["plaintext_recorded"]
    end
  end

  test "acceptance rejects unsafe baseline key mode" do
    with_bundle do |output, baseline_key, remote, _evidence, fake_bin|
      File.chmod(0o644, baseline_key)
      archive = File.join(output, "fixture-full-private.tar.gz.age")
      set_dir = File.join(output, "fixture-full-private-RECOVERY-SET")
      env = { "PATH" => "#{fake_bin}:#{ENV.fetch('PATH')}" }

      _stdout, stderr, status = run!(
        env,
        ACCEPT,
        "--archive", archive,
        "--recovery-set-dir", set_dir,
        "--baseline-key", baseline_key,
        "--driver", "filesystem",
        "--dest", remote
      )

      refute status.success?
      assert_includes stderr, "reason=unsafe-baseline-key-mode"
    end
  end
end
