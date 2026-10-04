# Ruby Envelope Vault 0.1.8 — Milestone 3 Off-host Runtime Portability

Date: 2026-10-04
Workspace: /content/DEV-0.1.8
Production authority during development: /content/RELEASE-0.1.7

## Result

DEV_0_1_8_MILESTONE_3_OFFSITE_RUNTIME_PORTABILITY=PASS

## Objective

Prevent release/promotion work from discovering a missing or unusable rclone
binary only after expensive release gates have already completed.

rclone tooling must remain outside sealed application source.

## External runtime resolver

Added:

/content/DEV-0.1.8/script/rclone-resolve

Resolution priority:

1. explicit RCLONE_BIN when executable and working;
2. RUNTIME_ROOT/bin/rclone;
3. an existing host PATH rclone.

If no usable binary exists, --provision invokes the portable provisioner.

## Portable pinned provisioner

Added:

/content/DEV-0.1.8/script/provision-rclone

Pinned release:

rclone v1.75.0

Supported portable Linux architectures:

- amd64
- arm64

Official archive SHA-256 pins:

- linux-amd64.zip:
  aa2804e08f48250e71009c727124b6341cd0288465804a9a09d14663cabafbaa
- linux-arm64.zip:
  d0ad88ba4c8e285b7c9efa591e0ab643280a91741e13c27f3a9c0957ccfa5203

The provisioner:

- downloads only from downloads.rclone.org over HTTPS;
- verifies the pinned archive SHA-256 before extraction;
- verifies the binary reports the expected version;
- installs only under external RUNTIME_ROOT/bin/rclone;
- never installs into the application source tree;
- can emit sanitized evidence containing version/platform/archive SHA/binary SHA;
- never records credentials.

Colab live result:

RCLONE_PROVISION=PASS status=installed version=1.75.0
RCLONE_BINARY_SHA256=f3f9aff817f9766029e50adf9a7963c169e475b8f10c7927823568a0d9443db7

Installed runtime location:

/content/.ruby-envelope-vault-runtime/bin/rclone

## Offsite capability preflight

Added:

/content/DEV-0.1.8/script/offsite-capability-preflight

The preflight validates before expensive release work:

- rclone config path is absolute/readable;
- config mode is 0600 or 0400;
- a named remote is used;
- remote is configured;
- local/memory/alias remotes are rejected for independent offsite storage;
- remote read capability succeeds;
- optional write/download/SHA/delete probe succeeds;
- rclone version and binary SHA are captured;
- config path, remote name/path and credentials are not written to evidence.

Real Colab/offsite test:

OFFSITE_CAPABILITY=PASS
RCLONE_VERSION=rclone v1.75.0
RCLONE_BINARY_SHA256=f3f9aff817f9766029e50adf9a7963c169e475b8f10c7927823568a0d9443db7
REMOTE_TYPE=s3
REMOTE_WRITE_PROBE=pass

The probe used a dedicated 0.1.8 capability prefix and deleted the probe object
after verification.

## Existing offsite scripts hardened

Updated:

- script/offsite-roundtrip
- script/offsite-dr-rehearsal

They no longer depend on a bare command -v rclone lookup.

They now:

- use script/rclone-resolve;
- require explicit RCLONE_CONFIG;
- pass --config to every rclone operation;
- use retries=3 and low-level-retries=3;
- invoke offsite-capability-preflight for strict remote operation.

## End-to-end wrapper validation

A non-secret synthetic probe was uploaded/downloaded through the updated
script/offsite-roundtrip and then removed from the remote.

Result:

M3_OFFSITE_ROUNDTRIP_WRAPPER=PASS

Round-trip probe SHA-256:

35cde1ad2ed785f1717b2a9464bb86c68bf250a87de0a52a9289a4fd55036e6a

## Early release gate

release-seal-prepromote now supports:

- RELEASE_REQUIRE_OFFSITE_PREFLIGHT
- RELEASE_OFFSITE_RCLONE_DEST
- RELEASE_RCLONE_CONFIG
- RELEASE_RCLONE_PROVISION
- RELEASE_OFFSITE_PROBE_WRITE

When RELEASE_REQUIRE_OFFSITE_PREFLIGHT=1, offsite capability runs immediately
after runtime activation and before release-verify.

The default strict path provisions rclone if needed and performs a write probe.

Evidence:

OFFSITE-CAPABILITY.json

Therefore missing rclone, unsafe config, invalid remote or write failure aborts
the release before the expensive Rails/system/security/recovery gates run.

## Regression coverage

Added:

/content/DEV-0.1.8/test/offsite_runtime_contract_test.rb

Coverage verifies:

- explicit external binary resolution;
- pinned version/checksum provisioner contract;
- runtime-only install scope;
- capability preflight sanitized evidence;
- unsafe config mode rejection;
- offsite preflight occurs before release-verify;
- offsite scripts use resolver/config/retries instead of bare PATH lookup.

Targeted regression:

- 65 runs
- 1224 assertions
- 0 failures
- 0 errors
- RuboCop targeted: 4 files / 0 offenses

## Full regression

- Rails: 189 runs / 1796 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 170 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1116 assertions / 0 failures

Final:

RELEASE_VERIFY=PASS version=0.1.8-dev

## Production safety

No change was made to RELEASE-0.1.7.

No current symlink change was performed.

No 0.1.8 production database was created.

The portable rclone binary lives only in the external runtime tree.

## Recommended next milestone

Add a release/promotion orchestration dry-run that exercises the full sequence
of provenance -> stable DB preparation -> offsite capability -> seal/promotion
contracts without repointing production, so 0.1.8 RC readiness can be tested
as one fail-closed workflow before creating RC-0.1.8.
