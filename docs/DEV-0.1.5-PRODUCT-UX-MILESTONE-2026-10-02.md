# DEV 0.1.5 Product UX Milestone — 2026-10-02

Base: sealed `RELEASE-0.1.4`
Active development tree: `/content/DEV-0.1.5`
Version: `0.1.5-dev`

## Scope

This milestone improves Vault usability without changing encryption, payload schemas, key handling, or version-history semantics.

Primary goals:
- make secret categories understandable before creation,
- explain which template fits which use case,
- make create/edit forms easier to scan,
- make edit/version behavior explicit,
- improve show-page lifecycle clarity,
- improve filter accessibility and correctness.

## Category guidance

All seven Vault kinds now include:
- user-facing label,
- description,
- "best for" guidance,
- typical field pattern,
- icon/accent metadata.
Templates covered:
- Login
- API key
- Environment
- Database
- Secure note
- Server / SSH
- Custom secret

The new-item chooser now displays use-case guidance for every category.

The selected category panel displays:
- category badge,
- best-fit explanation,
- typical fields,
- encrypted-before-persistence reminder.

## Form information architecture

The shared create/edit form is now separated into:
1. Item identity
2. Protected details
3. Organization

Existing field names and controller parameters remain unchanged for compatibility.

Edit mode now explicitly communicates:
- item type is fixed after creation,
- saving creates a new encrypted version,
- leaving the secret blank preserves the existing encrypted secret,
- changing the secret creates a new protected version.
## Item detail improvements

The item detail page now includes:
- About this template
- Protected field pattern
- explanation that field names are template metadata only
- a separate Item lifecycle section

Archive behavior is described as hiding an item from active results without deleting encrypted history.

Existing archive confirmation text remains compatible with established lifecycle regression tests.

## Search/filter bug discovered and fixed

During the UX regression, the browser correctly submitted:

`kind=login`

and the server correctly queried the filtered records.

However, the request was processed as `TURBO_STREAM` while the controller rendered a complete HTML page. Turbo therefore kept the old page instead of replacing it.

The search/filter form now disables Turbo for this POST only.

This preserves the existing privacy property:
- search terms remain out of the URL,
- POST filtering remains in place,
- rendered filter state now updates correctly.
Filter UX now also provides:
- accessible labels for type/state/tag selectors,
- visible "Filters active" state,
- Clear filters action while results are present.

## Regression evidence

New category/filter system coverage:
- 3 runs
- 34 assertions
- 0 failures
- 0 errors

Focused create/edit/show/lifecycle coverage:
- 3 runs
- 59 assertions
- 0 failures
- 0 errors

Responsive/mobile/accessibility subset:
- 10 runs
- 77 assertions
- 0 failures
- 0 errors

## Final verification

Rails:
- 124 runs
- 1051 assertions
- 0 failures
- 0 errors
System:
- 18 runs
- 166 assertions
- 0 failures
- 0 errors

Static/security:
- RuboCop: 157 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities

Crypto/security:
- crypto: 36 runs / 70 assertions / 0 failures
- security: 5 runs / 12 assertions / 0 failures

Accessibility:
- 45 runs
- 785 assertions
- 0 failures
- 0 errors

Final marker:

`RELEASE_VERIFY=PASS version=0.1.5-dev`

## Stable boundary

`RELEASE-0.1.4` remains sealed and unchanged.
All product UX work exists only in `DEV-0.1.5`.
