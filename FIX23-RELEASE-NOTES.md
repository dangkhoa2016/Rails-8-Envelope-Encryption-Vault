# FIX23 Release Notes — Product Polish

FIX23 is a product-polish release forked from the fully accepted FIX22 baseline.

## User-facing improvements

- Friendly Audit event titles and descriptions while preserving raw action identifiers.
- Friendly session device labels derived from the existing User-Agent:
  - browser,
  - operating system,
  - coarse device category.
- Raw User-Agent remains available under collapsed technical details.
- Configurable browser-only password/secret generator:
  - length 16–64;
  - uppercase;
  - lowercase;
  - numbers;
  - symbols;
  - avoid ambiguous characters;
  - secure defaults;
  - Web Crypto randomness.
- Accessibility improvements:
  - skip-to-content link;
  - main-content landmark target;
  - `aria-current="page"`;
  - mobile navigation `aria-controls` and state.
- README/showcase documentation updated for the current product and recovery model.
- Added architecture/security overview for portfolio/reference use.

## Operational improvement

Bootstrap now restores the executable bit on the persistent mise binary before deciding whether mise must be downloaded again. This avoids unnecessary re-download after persistence layers preserve bytes but lose executable mode.

## Security posture

FIX23 does not change the envelope-encryption model, encrypted payload schema, KEK separation, MFA design, reauthentication gates, rate limits, or immutable encrypted version history.

No additional session fingerprinting is introduced.
