# Ruby Envelope Vault 0.1.8 Development Roadmap

Base release: `RELEASE-0.1.7`
Development workspace: `/content/DEV-0.1.8`
Development version: `0.1.8-dev`

## Starting authority

0.1.8 begins only after 0.1.7 completed:

- full release verification;
- release-candidate private-DR gate;
- isolated restore;
- new-host recovery;
- AWS KMS fresh-host live rehearsal;
- historical AWS-KMS decrypt and rewrap;
- immutable release seal;
- production private DR based on the proven production snapshot;
- private-DR restore acceptance with counts 1/1/1/2/92;
- off-host encrypted DR round-trip;
- post-promotion metadata round-trip;
- production `/up=200` and `/ready=200`;
- operator-status PASS;
- sealed-source integrity PASS.

Production remains pinned to:
`/content/RELEASE-0.1.7`

Do not modify `RELEASE-0.1.7`.

## 0.1.8 initial priorities

1. Baseline 0.1.8 development workspace — PASS:
   - copied sealed 0.1.7 source into DEV-0.1.8;
   - set VERSION=0.1.8-dev;
   - kept production current on RELEASE-0.1.7;
   - hardened shared system-test login synchronization;
   - recovery-contract tests passed;
   - full release-verify passed before behavior changes.

2. Convert the 0.1.7 production-DR data-provenance lesson into a durable release contract — PASS (Milestone 1):
   - private DR release gate requires explicit provenance input;
   - exact archive SHA-256 is bound to provenance;
   - production-authority role is mandatory;
   - current runtime/DEV database source is rejected;
   - expected production cardinality minimums are enforced;
   - restore-acceptance counts must exactly match provenance counts;
   - inherited promoted snapshots require migration-set identity proof;
   - sanitized non-secret provenance evidence is emitted into release metadata/checklist.

3. Make production DB naming a first-class release contract — PASS (Milestone 2):
   - deterministic release database naming implemented;
   - production startup enforces stable database naming by default;
   - isolated acceptance mode requires explicit opt-out;
   - private DR can restore directly into an explicit stable database name;
   - failed keep-db acceptance cannot leave a partial database behind;
   - release-prepare-promotion prepares the stable DB before repointing;
   - promoted metadata requires stable DB preparation + live contract evidence.

4. Improve off-host tool/runtime portability — PASS (Milestone 3):
   - external runtime resolver added;
   - pinned portable rclone provisioner with archive SHA verification added;
   - independent remote capability preflight added;
   - read/write/download/delete probe supported;
   - offsite scripts now require explicit config and resolver-based binary;
   - strict release offsite preflight runs before release-verify;
   - rclone binary remains outside sealed source integrity.

5. Full release/promotion dry-run orchestration — PASS (Milestone 4):
   - canonical promoted-DR provenance was derived from the promoted 0.1.7 authority and bound to exact archive bytes;
   - strict offsite capability passed against the independent S3-compatible remote with write/download/SHA/delete probe;
   - full release verification passed inside the dry-run (Rails 200/1924, system 21/223, RuboCop 173 files/0 offenses, Brakeman 0 warnings, dependency audit 0 vulnerabilities);
   - the FIX45 global throttle preflight was hardened without changing the production 300 requests / 60 seconds contract: runtime contract is verified, counter is pre-seeded to 299, request 300 must return 200 and request 301 must return 429;
   - private-DR restore acceptance passed from the promoted production snapshot with counts 1/1/1/2/92, historical decrypt PASS, and HTTP up/ready 200/200;
   - AWS KMS fresh-host live rehearsal passed;
   - migration bundle internal/sidecar/portability verification passed;
   - new-host recovery acceptance passed from an isolated runtime with PROJECT_DOCTOR=PASS and HEALTH=200;
   - showcase capture, public package validation, isolated restore, and sealed-source integrity passed (426 files);
   - stable production DB preparation passed for ruby_envelope_vault_production_v0_1_8 and matched production provenance/counts;
   - dry-run cleanup removed the stable 0.1.8 DB after verification;
   - /content/current remained pinned to RELEASE-0.1.7 and production /up + /ready remained 200/200;
   - no repoint or promoted-production start occurred;
   - sanitized readiness evidence: tmp/m4-live-artifacts-v3/M4-DRY-RUN-READINESS.json;
   - final result: M4_DRY_RUN=PASS.

6. Preserve all current security/recovery gates:
   - fail-closed AWS KMS active-key authority;
   - secret-safe env intake;
   - historical decrypt compatibility;
   - encrypted backups only by default;
   - private-DR restore acceptance;
   - no credential/KMS/plaintext disclosure;
   - sealed-source integrity;
   - off-host round-trip before promotion.

## Development rules

- No changes directly in sealed release directories.
- No AWS KMS key rotation unless explicitly requested.
- Never print AWS credentials, KMS key IDs, or decrypted Vault payloads.
- Every behavior change requires focused regression tests plus release verification.
- Promotion must continue to depend on production-data DR evidence, not merely a successful DEV/test backup.
