# FIX21 Recovery Provenance

FIX21 was reconstructed on 2026-09-29 after the ephemeral /mnt/workspace source tree was lost across a container/device change.

Recovery inputs:
- authoritative FIX19 product-polish handoff retained in /kaggle/working;
- FIX16 migration bundle retained in /kaggle/working;
- persistent PostgreSQL 17 data, Ruby/Bundler/Selenium runtime, and KEK under /kaggle/working/.ruby-envelope-vault-runtime;
- prior FIX20 behavior and validation evidence from the previous session.

FIX21 intentionally avoids claiming byte-identical provenance with the lost FIX20 source artifact. It re-establishes and continues the validated product/security behavior under a new release identifier.
