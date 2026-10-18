require "test_helper"
require "open3"
require "tmpdir"

class PostpromoteFullPrivateBuilderTest < ActiveSupport::TestCase
  ROOT = Rails.root
  BUILDER = ROOT.join("script/build-postpromote-full-private").to_s

  def run!(*args)
    stdout, stderr, status = Open3.capture3(*args)
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

  def with_fixture
    Dir.mktmpdir do |dir|
      dev = File.join(dir, "DEV-0.1.8.3")
      rc = File.join(dir, "RC-0.1.8.2")
      rollback = File.join(dir, "RC-0.1.8.1")
      authority = File.join(dir, "authority")
      artifacts = File.join(dir, "artifacts")
      dump = File.join(dir, "production.dump")
      baseline_key = File.join(dir, "baseline.agekey")
      recipient = File.join(dir, "baseline-recipient.txt")
      output = File.join(dir, "output")

      make_repo(dev, "0.1.8.3-dev", "dev-0.1.8.3")
      make_repo(rc, "0.1.8.2", "rc-0.1.8.2")
      make_repo(rollback, "0.1.8.1", "rc-0.1.8.1")
      Dir.mkdir(authority)
      File.write(File.join(authority, "authority.txt"), "synthetic")
      Dir.mkdir(artifacts)
      File.write(File.join(artifacts, "RELEASE-METADATA.json"), JSON.pretty_generate(
        "release_version" => "0.1.8.2", "phase" => "promoted",
        "promotion_performed" => true, "release_verify" => "pass",
        "sealed_source_integrity" => "pass"
      ))
      File.binwrite(dump, "synthetic database dump")

      _out, err, st = run!("age-keygen", "-o", baseline_key)
      assert st.success?, err
      File.chmod(0o600, baseline_key)
      out, err, st = run!("age-keygen", "-y", baseline_key)
      assert st.success?, err
      File.write(recipient, out)

      yield dir, dev, rc, rollback, authority, artifacts, dump, recipient, output
    end
  end

  test "builder produces encrypted bundle and recovery set" do
    with_fixture do |_dir, dev, rc, rollback, authority, artifacts, dump, recipient, output|
      stdout, stderr, status = run!(
        BUILDER,
        "--dev-root", dev, "--rc-root", rc, "--rollback-root", rollback,
        "--private-authority", authority, "--release-artifacts", artifacts,
        "--database-dump", dump, "--baseline-recipient-file", recipient,
        "--output-dir", output, "--bundle-name", "fixture-full-private"
      )
      assert status.success?, stderr
      assert_includes stdout, "FULL_PRIVATE_BUILD=PASS version=0.1.8.2"
      assert File.file?(File.join(output, "fixture-full-private.tar.gz.age"))
      key = File.join(output, "fixture-full-private-OUTER-RECOVERY.agekey")
      set_dir = File.join(output, "fixture-full-private-RECOVERY-SET")
      assert File.file?(key)
      assert_equal 0o600, File.stat(key).mode & 0o777
      assert File.directory?(set_dir)
      refute File.exist?(File.join(set_dir, File.basename(key)))
    end
  end

  test "builder materializes top level repository symlinks" do
    with_fixture do |dir, dev, rc, rollback, authority, artifacts, dump, recipient, output|
      links = %w[DEV-LINK RC-LINK ROLLBACK-LINK].map { |name| File.join(dir, name) }
      [ dev, rc, rollback ].zip(links).each { |target, link| File.symlink(target, link) }
      stdout, stderr, status = run!(
        BUILDER,
        "--dev-root", links[0], "--rc-root", links[1], "--rollback-root", links[2],
        "--private-authority", authority, "--release-artifacts", artifacts,
        "--database-dump", dump, "--baseline-recipient-file", recipient,
        "--output-dir", output, "--bundle-name", "symlink-full-private"
      )
      assert status.success?, stderr
      assert_includes stdout, "FULL_PRIVATE_BUILD=PASS version=0.1.8.2"
    end
  end

  test "builder fails closed on dirty source repository" do
    with_fixture do |_dir, dev, rc, rollback, authority, artifacts, dump, recipient, output|
      File.write(File.join(dev, "DIRTY"), "dirty")
      _stdout, stderr, status = run!(
        BUILDER,
        "--dev-root", dev, "--rc-root", rc, "--rollback-root", rollback,
        "--private-authority", authority, "--release-artifacts", artifacts,
        "--database-dump", dump, "--baseline-recipient-file", recipient,
        "--output-dir", output, "--bundle-name", "fixture-full-private"
      )
      refute status.success?
      assert_includes stderr, "reason=dirty-source"
    end
  end
end
