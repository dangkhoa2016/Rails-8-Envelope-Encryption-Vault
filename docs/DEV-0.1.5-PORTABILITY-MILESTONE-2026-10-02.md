# DEV 0.1.5 Portability Milestone — 2026-10-02

Base: sealed `RELEASE-0.1.4`
Active development tree: `/content/DEV-0.1.5`
Version: `0.1.5-dev`

## Goals completed

- Ubuntu 24.04 / Colab package portability
- portable runtime activation
- portable new-host install/runtime defaults
- recovery without mandatory `/mnt/workspace`
- recovery startup without mandatory tmux
- PostgreSQL port-collision-safe Unix socket provisioning
- migration bundle secrets-root discovery without fixed `/mnt/workspace` default

## Runtime activation

New generic entrypoint: `activate-runtime.sh`.
Runtime selection order: Kaggle persistent path, Colab `/content`, then XDG/HOME fallback.
`activate-kaggle.sh` remains a backward-compatible wrapper.

## Ubuntu package portability

Bootstrap now selects `libasound2t64` when available and falls back to `libasound2`.
This fixes the Ubuntu 24.04 Noble failure found by the Google Colab off-host DR drill.

## PostgreSQL collision bug found and fixed

The isolated recovery test encountered occupied default ports:
- PostgreSQL: `5432 -> 5433`
- Redis: `6379 -> 6380`

The first recovery attempt exposed that socket-side `psql` and `createdb` calls did not pass the selected PostgreSQL port.
The fix makes provisioning use both the selected socket directory and selected port.

Focused recovery contracts after the fix:
`37 runs / 734 assertions / 0 failures / 0 errors`

## Isolated migration recovery acceptance

A fresh `0.1.5-dev` migration bundle was built from the DEV tree.

Markers:
- `BUNDLE_INTERNAL_VERIFY=PASS`
- `BUNDLE_PORTABILITY_VERIFY=PASS`
- `SOURCE_RESTORE=PASS`
- `SECRET_RESTORE=PASS`
- `EXECUTABLE_REPAIR=PASS`
- `PROJECT_DOCTOR=PASS`
- `RAILS_START_MODE=tmux`
- `HEALTH=200`
- `RAILS_PROCESS_VERIFY=PASS mode=tmux`
- `NEW_HOST_SUMMARY=PASS`
- `NEW_HOST_ACCEPTANCE=PASS version=0.1.5-dev`

## Final verification

- repository policy: PASS
- portability policy: PASS
- documentation links: PASS
- Zeitwerk: PASS
- Rails: 124 runs / 1051 assertions / 0 failures / 0 errors
- system: 15 runs / 132 assertions / 0 failures / 0 errors
- RuboCop: 156 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- crypto self-test: 36 runs / 70 assertions / 0 failures
- security self-test: 5 runs / 12 assertions / 0 failures
- accessibility smoke: 45 runs / 785 assertions / 0 failures

Final marker: `RELEASE_VERIFY=PASS version=0.1.5-dev`.

## Stable release boundary

`RELEASE-0.1.4` remains sealed and was not modified.
All portability changes live only in `DEV-0.1.5`.
