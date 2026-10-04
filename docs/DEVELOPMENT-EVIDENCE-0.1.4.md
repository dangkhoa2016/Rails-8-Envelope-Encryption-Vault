# 0.1.4-dev Development Evidence

## Scope

This is development-baseline evidence only. It is **not** RC/stable release acceptance and must not emit promotion markers.

Stable runtime remained on `RELEASE-0.1.3` throughout this work.

## Development provenance

- Initial fork: byte-for-byte copy of sealed stable 0.1.3.
- Initial stable/dev SHA manifests matched.
- Development version: `0.1.4-dev`.
- Stable `current` was not repointed to DEV.
- Stable sealed-source re-verification after changes: `PASS files=328`.
- Stable live health after changes: `200`.

## Changes established

1. Development roadmap and provenance documentation.
2. Secret-safe `script/operator-status`.
3. Manual accessibility evidence worksheet, still PENDING/UNTESTED.
4. Provider contract explicitly includes `verify_key!`.
5. `Vault::RotateKeys` resolves the configured provider through `Registry.fetch`.
6. Base provider contract regression test.
7. Test-only BCrypt minimum cost for practical functional regression execution.

## Runtime validation

Observed on the current Kaggle development environment:

- Rails: **111 runs / 980 assertions / PASS**
- System: **15 runs / 132 assertions / PASS**
- RuboCop: **149 files / 0 offenses**
- Brakeman: **0 security warnings**
- bundler-audit: **No vulnerabilities found**
- Crypto self-test: **26 runs / 49 assertions / PASS**
- Security self-test: **5 runs / 12 assertions / PASS**
- In-memory provider contract: **4 runs / 5 assertions / PASS**
- External KMS adapter contract: **7 runs / 20 assertions / PASS**
- Rotation integration suite: **4 runs / 28 assertions / PASS**
- Production registry external_kms registration: **CLOSED / PASS**
- Accessibility smoke: **42 runs / 737 assertions / PASS**
- Documentation link check: **PASS, checked=30**
- Repository policy: **PASS**
- Operator status: **PASS**
- PostgreSQL status through operator status: **ready**
- Redis status through operator status: **ready**

Recovery-code functional test after test-only BCrypt tuning:
- **1 run / 3 assertions / PASS**
- observed runtime approximately **0.39s**

## Accessibility claim boundary

Manual accessibility remains:

```text
PENDING / UNTESTED BY HUMAN
```

Automated accessibility PASS does not establish formal WCAG conformance.

## Snapshot policy

The development snapshot excludes runtime/generated/secret-bearing paths and patterns such as:

- `tmp/`
- `log/`
- `storage/`
- `.env*`
- `.bundle/`
- `*.key`, `*.pem`, `*.agekey`
- `rclone.conf`
- generated `public/assets/`

The snapshot is a continuation aid only. Future release artifacts must be produced by the formal release pipeline.
