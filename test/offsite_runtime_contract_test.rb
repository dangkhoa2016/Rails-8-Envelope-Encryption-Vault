require "test_helper"
require "json"
require "open3"
require "tmpdir"

class OffsiteRuntimeContractTest < ActiveSupport::TestCase
  RESOLVER = Rails.root.join("script/rclone-resolve")
  PREFLIGHT = Rails.root.join("script/offsite-capability-preflight")

  test "resolver accepts an explicit external working rclone binary" do
    Dir.mktmpdir do |dir|
      fake = File.join(dir, "rclone")
      File.write(fake, <<~SH)
        #!/bin/sh
        if [ "$1" = "version" ]; then
          echo "rclone v9.9.9-test"
          exit 0
        fi
        exit 0
      SH
      File.chmod(0o755, fake)

      stdout, stderr, status = Open3.capture3(
        { "RCLONE_BIN" => fake, "RUNTIME_ROOT" => File.join(dir, "runtime"), "PATH" => "/usr/bin:/bin" },
        RESOLVER.to_s
      )

      assert status.success?, stderr
      assert_equal File.realpath(fake), stdout.strip
    end
  end

  test "portable provisioner is pinned checksum verified and external to source tree" do
    script = Rails.root.join("script/provision-rclone").read

    assert_includes script, "RCLONE_PINNED_VERSION:-1.75.0"
    assert_includes script, "aa2804e08f48250e71009c727124b6341cd0288465804a9a09d14663cabafbaa"
    assert_includes script, "d0ad88ba4c8e285b7c9efa591e0ab643280a91741e13c27f3a9c0957ccfa5203"
    assert_includes script, "https://downloads.rclone.org/v"
    assert_includes script, 'dest_dir="$runtime_root/bin"'
    assert_includes script, "archive-sha256-mismatch"
    assert_includes script, '"install_scope":"external-runtime"'
    refute_includes script, 'dest_dir="$ROOT'
  end

  test "capability preflight validates remote without recording config or remote paths" do
    Dir.mktmpdir do |dir|
      fake = File.join(dir, "rclone")
      config = File.join(dir, "rclone.conf")
      evidence = File.join(dir, "evidence.json")

      File.write(fake, <<~SH)
        #!/bin/sh
        args="$*"
        case "$args" in
          *" version"|"version")
            echo "rclone v9.9.9-test"
            exit 0
            ;;
          *"config dump"*)
            echo '{"remote":{"type":"s3"}}'
            exit 0
            ;;
          *" lsf "*)
            exit 0
            ;;
        esac
        exit 1
      SH
      File.chmod(0o755, fake)
      File.write(config, "[remote]\ntype = s3\n")
      File.chmod(0o600, config)

      stdout, stderr, status = Open3.capture3(
        { "RCLONE_BIN" => fake, "RUNTIME_ROOT" => File.join(dir, "runtime"), "PATH" => "/usr/bin:/bin" },
        PREFLIGHT.to_s,
        "--dest", "remote:release-check/",
        "--config", config,
        "--evidence", evidence
      )

      assert status.success?, stderr
      assert_includes stdout, "OFFSITE_CAPABILITY=PASS"
      data = JSON.parse(File.read(evidence))
      assert_equal "pass", data["status"]
      assert_equal "s3", data["remote_type"]
      assert_equal "pass", data["remote_read"]
      assert_equal "not_requested", data["remote_write_probe"]
      assert_equal false, data["config_path_recorded"]
      assert_equal false, data["remote_name_recorded"]
      assert_equal false, data["remote_path_recorded"]
      assert_equal false, data["credential_values_recorded"]
      assert_equal false, data["contains_secret_values"]
    end
  end

  test "capability preflight consumes multiline rclone version without SIGPIPE" do
    Dir.mktmpdir do |dir|
      fake = File.join(dir, "rclone")
      config = File.join(dir, "rclone.conf")

      File.write(fake, <<~SH)
        #!/bin/sh
        args="$*"
        case "$args" in
          *" version"|"version")
            echo "rclone v9.9.9-test"
            i=0
            while [ "$i" -lt 20000 ]; do
              echo "detail line $i"
              i=$((i + 1))
            done
            exit 0
            ;;
          *"config dump"*)
            echo '{"remote":{"type":"s3"}}'
            exit 0
            ;;
          *" lsf "*)
            exit 0
            ;;
        esac
        exit 1
      SH
      File.chmod(0o755, fake)
      File.write(config, "[remote]\ntype = s3\n")
      File.chmod(0o600, config)

      stdout, stderr, status = Open3.capture3(
        { "RCLONE_BIN" => fake, "RUNTIME_ROOT" => File.join(dir, "runtime"), "PATH" => "/usr/bin:/bin" },
        PREFLIGHT.to_s,
        "--dest", "remote:release-check/",
        "--config", config
      )

      assert status.success?, "expected no SIGPIPE/141 failure: #{stderr}"
      assert_includes stdout, "OFFSITE_CAPABILITY=PASS"
      assert_includes stdout, "RCLONE_VERSION=rclone v9.9.9-test"
    end
  end

  test "pipefail operational scripts do not truncate producers with head" do
    candidates = [ Rails.root.join("bootstrap.sh"), *Rails.root.join("script").children.select(&:file?) ]

    offenders = candidates.filter_map do |path|
      content = path.read
      next unless content.include?("pipefail")
      next unless content.match?(/\|\s*head\b/)

      path.relative_path_from(Rails.root).to_s
    end

    assert_empty offenders, "unsafe pipefail/head pipelines: #{offenders.join(", ")}"
  end

  test "capability preflight rejects unsafe config permissions" do
    Dir.mktmpdir do |dir|
      config = File.join(dir, "rclone.conf")
      File.write(config, "[remote]\ntype = s3\n")
      File.chmod(0o644, config)

      _stdout, stderr, status = Open3.capture3(
        PREFLIGHT.to_s,
        "--dest", "remote:path/",
        "--config", config
      )

      refute status.success?
      assert_includes stderr, "unsafe-config-mode"
    end
  end

  test "release seal runs strict offsite capability before expensive verification" do
    script = Rails.root.join("script/release-seal-prepromote").read

    assert_includes script, "RELEASE_REQUIRE_OFFSITE_PREFLIGHT"
    assert_includes script, "RELEASE_RCLONE_PROVISION"
    assert_includes script, "RELEASE_OFFSITE_PROBE_WRITE"
    assert_includes script, "OFFSITE-CAPABILITY.json"

    preflight = script.index('"$ROOT/script/offsite-capability-preflight"')
    release_verify = script.index("./script/release-verify")
    assert preflight
    assert release_verify
    assert_operator preflight, :<, release_verify
  end

  test "offsite transfer paths use resolver explicit config and retries" do
    roundtrip = Rails.root.join("script/offsite-roundtrip").read
    rehearsal = Rails.root.join("script/offsite-dr-rehearsal").read

    [ roundtrip, rehearsal ].each do |script|
      assert_includes script, "script/rclone-resolve"
      assert_includes script, "RCLONE_CONFIG"
      assert_includes script, '--config "$RCLONE_CONFIG"'
      assert_includes script, "--retries 3"
      assert_includes script, "--low-level-retries 3"
      assert_includes script, "offsite-capability-preflight"
    end

    refute_includes roundtrip, "command -v rclone"
    refute_includes rehearsal, "command -v rclone"
  end
end
