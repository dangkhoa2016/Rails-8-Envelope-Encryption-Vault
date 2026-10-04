# FIX27 Release Notes — Recovery Observability

FIX27 is forked from the accepted FIX26 baseline.

Scope is deliberately limited to bootstrap/recovery observability. No cryptographic, database-schema, authentication, authorization, or vault-payload semantics are changed.

The bootstrap `setup` and `start` flows now emit a stable `RECOVERY_SUMMARY_BEGIN` / `RECOVERY_SUMMARY_END` block with:

- `reused_tools`
- `repaired_modes`
- `installed_packages`
- `assets_rebuilt`
- `database_reused`
- `postgres_reused`
- `redis_reused`

Counters describe the actions/inputs observed by the existing bootstrap path; they do not influence recovery decisions. Because bootstrap runtime code changed, FIX27 requires controlled-restart acceptance before promotion.
