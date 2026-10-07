# Ruby Envelope Vault 0.1.8.3 Development Roadmap

Base: frozen promoted reconstructed/equivalent verified `RC-0.1.8.2` at `811208bde15b815eea4855c1cfe7adde7cd08ebd`.

## Milestone 1 — Durable postpromote recovery-key custody

Status: PASS (reconstructed-equivalent after host restart).

- Wrap fresh FULL PRIVATE outer key to an independent age recipient.
- Record archive/wrapped-key/fresh-key SHA-256 metadata without recording private key contents.
- Keep raw fresh private key out of the recovery-set output.
- Fail closed on missing/tampered artifacts or unsafe key mode.

Reconstruction verification:
- focused tests: 4 runs / 44 assertions / 0 failures / 0 errors;
- existing recovery contract: 45 runs / 1136 assertions / 0 failures / 0 errors;
- RuboCop: 0 offenses.

## Milestone 2 — Canonical FULL PRIVATE packaging

Status: PASS (reconstructed-equivalent after host restart).

Canonical builder must assemble DEV/RC/rollback/private authority/release evidence/database dump, create an internal SHA manifest, encrypt with a fresh age identity, and invoke Milestone 1 custody.

## Milestone 3 — Canonical offsite recovery-chain acceptance

Status: PASS (reconstructed-equivalent after host restart).

Acceptance must prove remote upload/download, wrapped fresh-key recovery, archive decrypt, internal manifest, Git integrity, DB catalog and promoted metadata.

## Milestone 4 — Manual accessibility acceptance

Status: PASS.

Acceptance evidence:
- automated accessibility preflight: PASS;
- manual accessibility status: `COMPLETE_NO_BLOCKERS`;
- required human checks: 5/5 PASS;
- unresolved manual accessibility defects: none reported;
- evidence: `docs/UX-ACCESSIBILITY-MANUAL-EVIDENCE-0.1.8.3-dev.json`;
- worksheet: `docs/DEV-0.1.8.3-MILESTONE-4-MANUAL-ACCESSIBILITY-WORKSHEET-2026-10-07.md`;
- formal WCAG conformance is not claimed (`wcag_conformance=false`).

Automated accessibility evidence remains distinct from the recorded human acceptance evidence.

## Rules

- Never modify frozen `RC-0.1.8.2`.
- Never expose private age key contents, AWS credentials, KMS IDs, KEKs, DB passwords or decrypted Vault payloads.
- Before ephemeral-host shutdown, create and independently verify a portable/full-private backup.
