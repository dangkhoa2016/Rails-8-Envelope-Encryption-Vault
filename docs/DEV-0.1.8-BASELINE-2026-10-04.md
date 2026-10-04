# Ruby Envelope Vault 0.1.8 — Baseline Establishment

Date: 2026-10-04
Host: Google Colab CPU ef24490855d9

## Result

DEV_0_1_8_BASELINE=PASS

## Workspace creation

Created:

/content/DEV-0.1.8

from sealed production authority:

/content/RELEASE-0.1.7

The copy excluded runtime/generated/private material:

- .git
- .bundle
- .env / .env.*
- tmp
- log
- storage
- vendor/bundle
- compiled public assets

DEV VERSION:

0.1.8-dev

Production current remained:

/content/current -> /content/RELEASE-0.1.7

Before the copy, sealed release integrity verified:

SEALED_SOURCE_INTEGRITY=PASS files=405

## Runtime environment

Because source-tree .env files are intentionally excluded from DEV cloning,
the first targeted test correctly failed to connect to the test database.

The current development runtime env was then copied from DEV-0.1.7 into:

/content/DEV-0.1.8/.env.kaggle

Mode:

0600

This is development runtime state only and is not part of sealed source.

## System-test isolation finding

The first full baseline release verification exposed an order-dependent system
test race in the shared sign-in helper.

The helper clicked Sign in and returned immediately without establishing the
postcondition that redirect/authentication had completed.

Symptoms:

- isolated production UX file passed repeatedly;
- full system suite could query the dashboard before the authenticated root
  page had finished becoming current;
- the dashboard grid selector was therefore absent/null.

The isolated test file passed 3/3 repeated runs.

Fix in DEV-0.1.8:

sign_in_system_user now waits for:

- current path == root_path;
- [data-dashboard-main-grid] present.

This fixes the synchronization contract at the shared helper layer rather than
adding sleeps/retries to an individual test.

Post-fix full system suite:

- 21 runs
- 223 assertions
- 0 failures
- 0 errors

## Clean baseline verification

After synchronization hardening:

- repository policy: PASS
- portability policy: PASS
- documentation links: PASS
- Zeitwerk: PASS
- Rails: 168 runs / 1566 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 167 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1070 assertions / 0 failures
- RELEASE_VERIFY=PASS version=0.1.8-dev

Production remained pinned to RELEASE-0.1.7 throughout.
