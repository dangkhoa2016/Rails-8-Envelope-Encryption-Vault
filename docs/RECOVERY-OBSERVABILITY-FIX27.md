# FIX27 Recovery Observability

FIX27 adds observability only; it does not alter recovery decisions or cryptographic/database semantics.

`bootstrap.sh setup` and `bootstrap.sh start` emit a bounded summary:

```text
RECOVERY_SUMMARY_BEGIN
reused_tools=N
repaired_modes=N
installed_packages=N
assets_rebuilt=yes|no
database_reused=yes|no
postgres_reused=yes|no
redis_reused=yes|no
RECOVERY_SUMMARY_END
```

Semantics:
- `reused_tools`: persistent files discovered under the runtime `bin` directory.
- `repaired_modes`: persistent runtime tools whose executable bit was restored during this invocation.
- `installed_packages`: number of package entries requested by package-install paths during this invocation; it is an observability counter, not a claim that apt installed that many previously absent packages.
- `assets_rebuilt`: whether Tailwind/Propshaft rebuild ran.
- `database_reused`: whether an existing PostgreSQL data directory was reused.
- `postgres_reused`: whether PostgreSQL was already running rather than restarted.
- `redis_reused`: whether managed Redis was already running with matching credentials.

Controlled restart evidence on 2026-09-29 intentionally changed `cloudflared`, `mise`, and `rclone` from executable to non-executable mode, then ran the normal FIX27 start path. It reported `repaired_modes=3`, preserved application DB counts exactly, and required no package installation.
