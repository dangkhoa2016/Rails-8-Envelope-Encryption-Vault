require "test_helper"
require "digest"
require "json"
require "open3"
require "tmpdir"

class PrivateDrProvenancePreflightTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/private-dr-provenance-preflight")
  RELEASE_VERSION = Rails.root.join("VERSION").read.strip

  test "accepts production authority provenance tied to the accepted archive" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)

      stdout, stderr, status = Open3.capture3(
        SCRIPT.to_s,
        "--archive", archive,
        "--provenance", provenance,
        "--acceptance", acceptance,
        "--evidence", evidence
      )

      assert status.success?, stderr
      assert_includes stdout, "PRIVATE_DR_PROVENANCE=PASS"
      data = JSON.parse(File.read(evidence))
      assert_equal "pass", data["status"]
      assert_equal "production-authority", data["snapshot_role"]
      assert_equal RELEASE_VERSION, data["target_release_version"]
      assert_equal false, data["source_equals_runtime_database"]
      assert_equal false, data["contains_secret_values"]
      assert_equal 0o644, File.stat(evidence).mode & 0o777
    end
  end

  test "rejects provenance that points at the current runtime database" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)
      mutate_json(provenance) { |data| data["source_equals_runtime_database"] = true }

      _stdout, stderr, status = run_preflight(archive, provenance, acceptance, evidence)

      refute status.success?
      assert_includes stderr, "runtime-database-source-not-forbidden"
      refute File.exist?(evidence)
    end
  end

  test "rejects provenance for another release version" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)
      mutate_json(provenance) { |data| data["target_release_version"] = "0.0.0" }

      _stdout, stderr, status = run_preflight(archive, provenance, acceptance, evidence)

      refute status.success?
      assert_includes stderr, "target-release-version-mismatch"
    end
  end

  test "rejects production snapshot counts below release minimums" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)
      mutate_json(provenance) { |data| data["database_counts"]["vault_items"] = 0 }
      mutate_json(acceptance) { |data| data["database_counts"]["vault_items"] = 0 }

      _stdout, stderr, status = run_preflight(archive, provenance, acceptance, evidence)

      refute status.success?
      assert_includes stderr, "count-below-minimum-vault_items"
    end
  end

  test "rejects provenance counts that differ from restore acceptance" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)
      mutate_json(provenance) { |data| data["database_counts"]["audit_events"] = 93 }

      _stdout, stderr, status = run_preflight(archive, provenance, acceptance, evidence)

      refute status.success?
      assert_includes stderr, "acceptance-database-counts-mismatch"
    end
  end

  test "inherited promoted DR requires migration-set identity proof" do
    Dir.mktmpdir do |dir|
      archive, provenance, acceptance, evidence = build_fixture(dir)
      mutate_json(provenance) do |data|
        data["source_release_version"] = "0.1.7"
        data["migration_set_identical"] = false
      end

      _stdout, stderr, status = run_preflight(archive, provenance, acceptance, evidence)

      refute status.success?
      assert_includes stderr, "inherited-snapshot-migration-contract-not-proven"
    end
  end

  private

  def run_preflight(archive, provenance, acceptance, evidence)
    Open3.capture3(
      SCRIPT.to_s,
      "--archive", archive,
      "--provenance", provenance,
      "--acceptance", acceptance,
      "--evidence", evidence
    )
  end

  def build_fixture(dir)
    archive = File.join(dir, "ruby-envelope-vault-private-dr.tar.gz.age")
    provenance = File.join(dir, "provenance.json")
    acceptance = File.join(dir, "acceptance.json")
    evidence = File.join(dir, "evidence.json")

    File.binwrite(archive, "synthetic encrypted archive fixture")
    archive_sha = Digest::SHA256.file(archive).hexdigest
    counts = {
      "users" => 1,
      "vault_items" => 1,
      "vault_item_versions" => 1,
      "key_registries" => 2,
      "audit_events" => 92
    }

    File.write(provenance, JSON.pretty_generate({
      "schema_version" => 1,
      "status" => "pass",
      "snapshot_role" => "production-authority",
      "source_type" => "promoted-private-dr",
      "source_release_version" => RELEASE_VERSION,
      "target_release_version" => RELEASE_VERSION,
      "artifact" => File.basename(archive),
      "artifact_sha256" => archive_sha,
      "production_authority_confirmed" => true,
      "source_equals_runtime_database" => false,
      "migration_set_identical" => true,
      "database_counts" => counts,
      "contains_secret_values" => false,
      "credential_values_recorded" => false,
      "key_ids_recorded" => false,
      "plaintext_recorded" => false
    }))

    File.write(acceptance, JSON.pretty_generate({
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
    }))

    [ archive, provenance, acceptance, evidence ]
  end

  def mutate_json(path)
    data = JSON.parse(File.read(path))
    yield data
    File.write(path, JSON.pretty_generate(data))
  end
end
