# FIX28 Release Notes — Machine-readable Recovery Diagnostics

- Adds JSON form of the FIX27 recovery summary.
- Persists the latest non-secret bootstrap diagnostic under the persistent runtime diagnostics directory.
- Adds `script/release-verify` to orchestrate existing release gates without weakening them.
- No cryptographic, schema, authentication, authorization, or vault-payload semantics changed.
