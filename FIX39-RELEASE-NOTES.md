# Ruby Envelope Vault 0.1.2-FIX39

## Scope

FIX39 hardens portable new-host recovery for Kaggle/Notebook Linux environments.

## Changes

- Added `script/restore-new-host` as the one-command recovery orchestrator.
- Migration bundle internal manifest is verified before restore.
- Canonical source and secret roots are restored through the bundle's official `restore-to-linux.sh`.
- Runtime executable modes are repaired before bootstrap.
- Bootstrap automatically selects warm-start or full setup according to persisted runtime availability.
- `project-doctor` is mandatory before Rails startup.
- Puma is started in a managed tmux window and health must return HTTP 200.
- A non-secret `NEW-HOST-RECOVERY-SUMMARY.json` records recovery outcome.
- Port, tmux session, install root, secret root and bootstrap mode are overrideable for isolated acceptance tests.

## Security boundary

FIX39 does not change encryption, KEK/DEK semantics, MFA, sessions, or encrypted-record schema. Secret values are never written to the machine-readable recovery summary.
