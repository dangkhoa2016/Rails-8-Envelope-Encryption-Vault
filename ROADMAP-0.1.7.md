# Ruby Envelope Vault 0.1.7 Development Roadmap

Base release: `RELEASE-0.1.6.1`
Development workspace: `/content/DEV-0.1.7`
Development version: `0.1.7-dev`

## Starting authority

0.1.7 begins only after 0.1.6.1 completed:

- sealed release integrity verification
- promoted production boot
- private DR packaging
- outer age encryption
- off-host upload/download SHA256 round-trip
- exact fresh-host recovery on a separate Google Colab
- encrypted PostgreSQL restore
- historical AWS KMS decrypt
- sealed production boot from the recovered host
- AWS KMS active-key alias drift repair without key rotation

Production remains pinned to:
`/content/RELEASE-0.1.6.1`

Do not modify `RELEASE-0.1.6.1`.

## 0.1.7 initial priorities

1. Convert the AWS KMS active-key alias lesson into a durable configuration guard — PASS (Milestones 1-2):
   - ensure the configured active KMS key matches the active KeyRegistry row;
   - fail closed before accepting new writes if they disagree;
   - keep decrypt-only historical keys readable;
   - detect the same mismatch during production boot/readiness/operator diagnostics.

2. Improve recovery/operator ergonomics — IN PROGRESS:
   - fresh-host source/runtime restore verified on a second Colab;
   - CRLF credential env normalization implemented in protected copies;
   - uploaded secret mode enforcement implemented;
   - AWS KMS secret semantic preflight implemented without value disclosure;
   - exact recovery artifacts/checks documented;
   - NEXT: wire these helpers directly into restore/bootstrap entrypoints.

3. Consolidate production startup configuration — PASS (Milestone 3):
   - separate stable production runtime/env paths from DEV workspace paths;
   - avoid live helpers depending on a mutable DEV directory;
   - require external production env mode 0600/0400;
   - refuse source-tree production env files.

4. Harden recovery/operator secret-file ergonomics — PASS (Milestone 4):
   - normalize CRLF into protected temporary copies;
   - enforce restrictive file mode before sourcing;
   - expose only safe presence/mode/format diagnostics;
   - detect stale AWS KMS active aliases without printing key IDs;
   - never print credentials or KMS key IDs.

5. Integrate secret-safe intake into fresh-host restore/bootstrap — PASS (Milestone 5):
   - require generic data-only secret preflight before sourcing uploaded env files;
   - reject executable shell statements in uploaded env files;
   - require AWS KMS semantic preflight before AWS-backed readiness/live smoke;
   - require 0600/0400 input mode unless explicit mode-fix opt-in is used;
   - remove normalized credential copies after generic recovery preflight;
   - keep the uploaded original semantically immutable.

6. Build first-class one-command private DR restore orchestration — PASS (Milestone 6):
   - verify/decrypt promoted encrypted DR artifact;
   - restore isolated PostgreSQL DB through the app role;
   - perform secret-safe AWS intake + active-key preflight before DR decrypt;
   - self-heal managed PostgreSQL/Redis when needed;
   - verify historical decrypt and production readiness;
   - clean staged plaintext and isolated DB automatically;
   - emit only machine-readable non-secret evidence.

7. Prepare 0.1.7 release-candidate sealing — NEXT:
   - run release-verify from DEV-0.1.7;
   - require one-command private-DR acceptance as a release gate;
   - create immutable RELEASE-0.1.7 only after every gate passes;
   - build new 0.1.7 migration/private-DR artifacts;
   - verify sealed-source integrity and fresh-host recovery;
   - promote only after final DR evidence PASS.

8. Preserve all current security gates:
   - release verification;
   - encrypted backups;
   - historical decrypt compatibility;
   - fail-closed provider mismatch behavior;
   - no secret/plaintext logging.

## Development rules

- No changes directly in sealed release directories.
- No AWS KMS key rotation unless explicitly requested.
- Never print AWS credentials, KMS key IDs, or decrypted Vault payloads into evidence/logs.
- Every behavior change must have regression coverage.
- Before any future 0.1.7 release candidate, re-run DB restore and historical decrypt acceptance.
