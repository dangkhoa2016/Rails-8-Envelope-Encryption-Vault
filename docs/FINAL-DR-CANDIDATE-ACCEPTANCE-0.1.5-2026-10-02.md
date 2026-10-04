# Ruby Envelope Vault 0.1.5 Final Private DR Candidate Acceptance — 2026-10-02

Candidate artifact:
/content/RUBY-ENVELOPE-VAULT-v0.1.5-PRIVATE-DR-CANDIDATE-20261002T142817Z.tar.gz

SHA256:
e922c52eed1e528471d35a34b439d8d3000585bbf1b682cf40018c825c04410a

Archive mode: 0600
Archive size: 978315 bytes

Fresh encrypted database SHA256:
c627daf039cac7342f37959c50d58348d7b6eef786a366218b040b07a2388555

Final migration candidate SHA256:
a65286ddcbacc7ef0ded0f42168a94ad88e4e248f3b5e57d7bffc5c376bff91f

## Final artifact gates

- outer SHA256 sidecar verify: PASS
- internal MANIFEST-SHA256 verify: PASS
- AWS temporary session/cache leak scan: PASS
- rollback RELEASE-0.1.4 present: PASS
- candidate DEV-0.1.5 present: PASS
- fresh encrypted DB present: PASS
- recovery age identity and Vault KEKs present: PASS
- migration candidate + sidecar present: PASS

## Exact final-archive rehearsal

The exact artifact above was extracted into an isolated rehearsal directory.

Markers:
- REV015_FINAL_DR_INTERNAL_MANIFEST=PASS
- REV015_FINAL_DR_FRESH_DB=PASS
- REV015_FINAL_DR_DATABASE_RESTORE=PASS
- encrypted backup checksum/catalog verification=PASS
- REV015_FINAL_DR_DATABASE_COUNTS=PASS
- REV015_FINAL_DR_VAULT_REVEAL=PASS
- REV015_FINAL_DR_HEALTH=200

The canary reveal printed no plaintext.

## Release-readiness relationship

This DR artifact contains the release-readiness evidence produced before the final
outer artifact hash was known. This outer acceptance document records the final
archive hash separately to avoid a self-referential archive-hash cycle.

FINAL_DR_CANDIDATE_ACCEPTANCE=PASS
RELEASE_BLOCKERS=0
