# Qualification matrix — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](qualification.vi.md)

## How to read this matrix

Qualification is tied to a **specific Git revision and environment**. An automated PASS establishes that the named contract was exercised; it does not prove a permanent production host is secure, that every failure mode was covered, or that an independent penetration test occurred.

| Area | Automated source check | Remaining operational acceptance |
| --- | --- | --- |
| Rails correctness | `bin/rails test`, request/service tests | Account policy and real user workflow on the target host |
| Browser behavior | `bin/rails test:system` | Actual browser/device and accessibility assessment |
| Authenticated encryption | `script/crypto-self-test` and crypto tests | Live KEK custody, rotation policy and recovery rights |
| Security controls | `script/security-self-test`, request tests | Production MFA, session, origin and proxy settings |
| Ruby and dependencies | RuboCop, Brakeman, bundler-audit | Continuous dependency review and incident response |
| Compatibility | Ruby 3.4 and Ruby 4.0 CI jobs | Actual runtime/container/kernel compatibility |
| Persistence | PostgreSQL 17 CI service | Database backups, access restrictions and monitoring |
| Container build | `docker build --pull --no-cache` | Live image deployment, TLS, network and secrets injection |
| Documentation | `script/doc-quality-check` | Operator review of procedures and local changes |
| Recovery | Script tests, isolated synthetic rehearsals | Offsite retrieval, independent age/KEK custody, restored canary |
| Accessibility | Automated keyboard/UI checks | Manual screen-reader, touch, contrast and focus sign-off |

## Reference workflow

The versioned [CI workflow](../.github/workflows/ci.yml) and [Documentation workflow](../.github/workflows/docs.yml) define the checks. Review the [CI runs](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions/workflows/ci.yml) and [Documentation runs](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions/workflows/docs.yml) for the intended release. Count a passing run as evidence only when its head SHA matches the exact release commit; an old run or badge does not validate rewritten history.

The six-job CI result from the initial release review was a **point-in-time result**, not a permanent badge value. Prefer the live workflow badge for current status.

## Minimum criteria before a source release

1. Confirm the intended branch/tag and exact commit SHA.
2. Confirm CI, documentation workflow and security jobs correspond to that revision.
3. Run local link/translation integrity checks and inspect document claims for unsupported guarantees.
4. Check Git diff, license attribution, repository policy and unexpected sensitive files.
5. Validate the source package or container build if it is included in the intended release.
6. Document unresolved limitations in a deployment-specific acceptance report; use the [Production checklist](PRODUCTION-CHECKLIST.md) for operator sign-off.

## Additional criteria before production use

- Establish TLS/reverse proxy and strict host/origin/CSRF settings on the **actual** endpoint.
- Demonstrate KEK access control and independent recovery custody.
- Restore an offsite encrypted backup into a guarded fresh DB; decrypt a synthetic canary.
- Confirm MFA, role/ownership boundaries, session revocation and logging redaction on the deployed host.
- Review accessibility with human testers and document operator sign-off.
- Revalidate after the last code, configuration or infrastructure change.

## Evidence classification

| Classification | Meaning |
| --- | --- |
| **SOURCE PASS** | Repeatable check of repository code or generated package at a fixed SHA |
| **SYNTHETIC PASS** | Demonstration with isolated fake secrets and controlled environments |
| **HOST PASS** | Operator completed a documented check on a specific live host |
| **PENDING** | No current evidence satisfying that exact acceptance condition |
| **NOT CLAIMED** | Outside project scope, such as zero-knowledge, formal audit, SLA or certification |

Do not relabel old private evidence as proof of a changed release. See the [Evidence index](evidence-index.md), [Reproducibility guide](reproducibility.md) and [Deployment guide](deployment.md).
