# Release Workflow — FIX31

The proven release flow is intentionally split into explicit phases:

1. Fork the previous authoritative release.
2. Run `script/release-seal-prepromote` to execute verification, artifact build, leak checks, showcase capture, isolated restore, checksums, and pre-promotion metadata.
3. Review `PROMOTION_REQUIRED=yes`; promotion is deliberately not automatic.
4. Promote the `current` symlink and restart the live Puma process as an explicit operator action.
5. Run project doctor and health checks.
6. Round-trip canonical artifacts to off-host storage.
7. Run `script/release-postpromote-evidence` to regenerate promoted metadata and verify its off-host copy.
8. Run `script/release-checklist` for the operator checklist.
9. Run `script/release-history` to refresh the non-secret release history index.

## Evidence provenance

FIX29 and newer are metadata-native. FIX28 predates `RELEASE-METADATA.json`; its history entry is derived only from its authoritative handoff plus persistent SHA256SUMS and is explicitly marked legacy. The release-history generator must not silently retrofit FIX28 as if native metadata had existed.

## Accessibility boundary

Automated accessibility smoke results are release evidence, but they are not a substitute for manual keyboard, screen-reader, contrast, zoom/reflow, or touch-target verification.
