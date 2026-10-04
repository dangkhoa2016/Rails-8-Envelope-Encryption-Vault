# Upgrade Guide — 0.1.2-FIX46 to 0.1.3

## Supported base

The consolidation upgrade is defined from the accepted `0.1.2-FIX46` release.

## Database contract

0.1.3 contains the same migration set as FIX46. The schema head remains migration `20260927001300_add_totp_replay_protection.rb`.

The release preflight compares migration filenames between the accepted FIX46 source and the stable release, runs production `bin/rails db:migrate`, proves that the schema-migration head and count do not change, and verifies that no migration remains pending.

## Runtime/data reuse

The stable release is designed to reuse the existing persistent PostgreSQL database and runtime services. The upgrade preflight runs `script/project-doctor` from the stable source against that existing environment.

No secret values, database URL, KEK material, rclone credentials or cookie values are written to the upgrade evidence.

## Operator sequence

1. Keep FIX46 as the live `current` release.
2. Build and verify stable 0.1.3 separately.
3. Run `script/upgrade-from-fix46-preflight`.
4. Run the full release verification and pre-promotion seal.
5. Do not change `current` until the seal reports `PREPROMOTE_SEAL=PASS` and `PROMOTION_REQUIRED=yes`.
6. Promote explicitly and restart Puma.
7. Run post-promotion evidence.
8. Round-trip all canonical artifacts and evidence through the configured off-host destination.
9. Verify the sealed-source manifest again.

## Rollback

Because the candidate adds no migration beyond FIX46, rollback of application source is the normal explicit symlink/Puma rollback to FIX46. Database rollback is not part of this milestone because no new database migration is introduced.

## Manual boundary

Automated accessibility evidence remains separate from human/manual accessibility acceptance. This upgrade does not claim formal WCAG conformance.
