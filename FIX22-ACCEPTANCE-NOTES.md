# FIX22 Product Acceptance Fixes

FIX22 continues from the recovered and validated FIX21 baseline.

Acceptance findings fixed:
- explicit `settings/security` route mapping to `Settings::SecurityController`;
- stale precompiled Propshaft/Tailwind assets no longer survive release packaging;
- bootstrap rebuilds Tailwind + Propshaft assets and verifies responsive utilities;
- desktop sidebar layout is protected by a computed-style system regression test;
- mobile navigation starts collapsed and opens via the hamburger control;
- Dashboard mobile min-content overflow is fixed;
- key authenticated mobile pages are regression-tested for horizontal overflow;
- compact mobile header uses icon controls for create/sign-out.

FIX21 remains the off-host recovery baseline; FIX22 is the first release derived from manual visual/product acceptance after recovery.
