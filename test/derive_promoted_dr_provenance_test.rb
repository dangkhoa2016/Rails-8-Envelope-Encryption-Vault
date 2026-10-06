require "test_helper"
require "digest"
require "json"
require "open3"
require "tmpdir"
require "fileutils"

class DerivePromotedDrProvenanceTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/derive-promoted-dr-provenance")

  test "derives sanitized promoted DR provenance with byte and migration binding" do
    Dir.mktmpdir do |dir|
      fx = build_fixture(dir)

      stdout, stderr, status = run_script(fx)

      assert status.success?, stderr
      assert_includes stdout, "DERIVE_PROMOTED_DR_PROVENANCE=PASS"
      assert_includes stdout, "MIGRATION_SET_IDENTICAL=PASS files=2"

      data = JSON.parse(File.read(fx[:output]))
      assert_equal "pass", data["status"]
      assert_equal "production-authority", data["snapshot_role"]
      assert_equal "promoted-private-dr", data["source_type"]
      assert_equal "0.1.7", data["source_release_version"]
      assert_equal "0.1.8-dev", data["target_release_version"]
      assert_equal Digest::SHA256.file(fx[:archive]).hexdigest, data["artifact_sha256"]
      assert_equal true, data["migration_set_identical"]
      assert_equal 2, data["migration_file_count"]
      assert_equal false, data["contains_secret_values"]
      assert_equal 0o644, File.stat(fx[:output]).mode & 0o777
    end
  end

  test "rejects source metadata that is not promoted" do
    Dir.mktmpdir do |dir|
      fx = build_fixture(dir)
      mutate_json(fx[:metadata]) { |d| d["phase"] = "prepromote" }

      _stdout, stderr, status = run_script(fx)

      refute status.success?
      assert_includes stderr, "source-release-not-promoted"
      refute File.exist?(fx[:output])
    end
  end

  test "rejects acceptance not bound to promoted metadata" do
    Dir.mktmpdir do |dir|
      fx = build_fixture(dir)
      mutate_json(fx[:acceptance]) { |d| d["database_counts"]["audit_events"] = 93 }

      _stdout, stderr, status = run_script(fx)

      refute status.success?
      assert_includes stderr, "source-acceptance-sha256-mismatch"
    end
  end

  test "rejects archive whose bytes do not match promoted sidecar" do
    Dir.mktmpdir do |dir|
      fx = build_fixture(dir)
      File.binwrite(fx[:archive], "tampered bytes")

      _stdout, stderr, status = run_script(fx)

      refute status.success?
      assert_includes stderr, "archive-sha256-mismatch"
    end
  end

  test "rejects migration content drift even when filenames match" do
    Dir.mktmpdir do |dir|
      fx = build_fixture(dir)
      File.write(File.join(fx[:target_migrations], "002_second.rb"), "changed\n")

      _stdout, stderr, status = run_script(fx)

      refute status.success?
      assert_includes stderr, "migration-set-not-identical"
    end
  end

  private

  def run_script(fx)
    Open3.capture3(
      SCRIPT.to_s,
      "--archive", fx[:archive],
      "--archive-sha-file", fx[:archive_sha_file],
      "--source-metadata", fx[:metadata],
      "--source-acceptance", fx[:acceptance],
      "--source-migrations", fx[:source_migrations],
      "--target-migrations", fx[:target_migrations],
      "--output", fx[:output]
    )
  end

  def build_fixture(dir)
    archive = File.join(dir, "source-private-dr.tar.gz.age")
    archive_sha_file = "#{archive}.sha256"
    metadata = File.join(dir, "RELEASE-METADATA.json")
    acceptance = File.join(dir, "PRIVATE-DR-RESTORE-ACCEPTANCE.json")
    source_root = File.join(dir, "source")
    target_root = File.join(dir, "target")
    source_migrations = File.join(source_root, "db", "migrate")
    target_migrations = File.join(target_root, "db", "migrate")
    output = File.join(dir, "derived-provenance.json")

    FileUtils.mkdir_p(source_migrations)
    FileUtils.mkdir_p(target_migrations)

    File.binwrite(archive, "synthetic encrypted production authority")
    archive_sha = Digest::SHA256.file(archive).hexdigest
    File.write(archive_sha_file, "#{archive_sha}  #{archive}\n")

    File.write(File.join(source_migrations, "001_first.rb"), "first\n")
    File.write(File.join(source_migrations, "002_second.rb"), "second\n")
    FileUtils.cp(File.join(source_migrations, "001_first.rb"), target_migrations)
    FileUtils.cp(File.join(source_migrations, "002_second.rb"), target_migrations)
    File.write(File.join(target_root, "VERSION"), "0.1.8-dev\n")

    counts = {
      "users" => 1,
      "vault_items" => 1,
      "vault_item_versions" => 1,
      "key_registries" => 2,
      "audit_events" => 92
    }

    acceptance_doc = {
      "schema_version" => 1,
      "artifact" => File.basename(archive),
      "outer_decrypt" => "pass",
      "database_restore" => "pass",
      "historical_decrypt" => "pass",
      "http_up" => 200,
      "http_ready" => 200,
      "database_counts" => counts,
      "credential_values_recorded" => false,
      "key_ids_recorded" => false,
      "plaintext_recorded" => false
    }
    File.write(acceptance, JSON.pretty_generate(acceptance_doc))
    acceptance_sha = Digest::SHA256.file(acceptance).hexdigest

    metadata_doc = {
      "schema_version" => 1,
      "phase" => "promoted",
      "promotion_performed" => true,
      "release_verify" => "pass",
      "release_version" => "0.1.7",
      "private_dr_restore_acceptance" => "pass",
      "private_dr_acceptance_sha256" => acceptance_sha,
      "private_dr_database_counts" => counts
    }
    File.write(metadata, JSON.pretty_generate(metadata_doc))

    {
      archive: archive,
      archive_sha_file: archive_sha_file,
      metadata: metadata,
      acceptance: acceptance,
      source_migrations: source_migrations,
      target_migrations: target_migrations,
      output: output
    }
  end

  def mutate_json(path)
    data = JSON.parse(File.read(path))
    yield data
    File.write(path, JSON.pretty_generate(data))
  end
end
