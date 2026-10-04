# FIX26 Release Notes — Public Showcase & Demo Safety

FIX26 is forked from the accepted FIX25 baseline.

Initial scope implemented:

- visible synthetic-data-only banner when `DEMO_MODE=true`;
- expanded deterministic screenshot coverage for item detail, immutable version history and Security;
- screenshot SHA-256 and dimensions/bytes manifest;
- allowlist-built public showcase package with denylist and secret-pattern checks;
- public showcase documentation.

FIX25 remains immutable. Encryption, KEK/DEK semantics, database schema and authorization flows are unchanged.

Additional UX evidence:

- Audit category chips now show counts.
- Each audit event displays its friendly category badge while preserving the raw action identifier.
- Action choices are constrained to the selected category.
- Manual accessibility evidence checklist added with explicit PENDING states rather than an unsupported compliance claim.
