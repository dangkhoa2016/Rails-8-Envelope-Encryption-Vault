# FIX28 Recovery Diagnostics

FIX28 extends the FIX27 human-readable recovery summary with a machine-readable, non-secret JSON diagnostic artifact.

Default location:

`$RUNTIME_ROOT/diagnostics/latest-bootstrap-summary.json`

The JSON contains only release/command/timestamp and recovery counters/booleans. It intentionally excludes environment variables, database or Redis URLs, passwords, KEK/recovery-key paths, hostnames, and other secret-bearing configuration.

The file is replaced on each successful `bootstrap.sh setup` or `bootstrap.sh start` summary emission and is mode 0644 so operators can inspect it without exposing secret material.

`script/release-verify` orchestrates the existing repository, portability, Rails, system, lint, security, crypto and accessibility gates. It does not replace artifact build, isolated restore, controlled restart, or off-host round-trip requirements.
