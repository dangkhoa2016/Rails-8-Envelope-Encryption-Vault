# Manual Accessibility Evidence — 0.1.4

## Status

**PENDING / UNTESTED BY HUMAN**

This document is a repeatable evidence worksheet. Its existence does not establish WCAG conformance and does not change the 0.1.3/0.1.4 manual-accessibility status to PASS.

## Test conditions to record

- Date/time:
- Reviewer:
- Browser/version:
- Operating system:
- Screen reader/version, if used:
- Viewport(s):
- Zoom level(s):
- Build/version under review:
- Source commit/archive identifier:

## Global keyboard pass

For every primary page, verify and record:
- all interactive controls reachable by keyboard;
- focus order follows the visual/task order;
- focus indicator remains visible;
- no keyboard trap;
- skip/navigation behavior is predictable;
- Enter/Space activate controls as expected;
- Escape behavior is sensible where dialogs/temporary UI exist.

Result: **UNTESTED**

## Required task flows

### Authentication
- Login form labels and instructions.
- Validation errors associated with fields.
- Registration flow, when enabled.
- MFA challenge using TOTP.
- MFA challenge using one-time recovery code.

Result: **UNTESTED**

### Vault list and search/filter
- Navigate list, filters, pagination and item actions.
- Search without loss of focus/context.
- Empty state is understandable.
- Archived/current states are distinguishable without color alone.

Result: **UNTESTED**

### Create and edit
- Labels, required state and help text announced correctly.
- Secret/password controls are keyboard usable.
- Error summary/field errors are discoverable.
- Save/cancel flow has predictable focus.

Result: **UNTESTED**

### Reveal and reauthentication
- Reauthentication requirement is understandable.
- Reveal control has a meaningful accessible name/state.
- Revealed content does not create an unexpected focus trap.
- Clipboard/copy feedback is perceivable without relying only on color.

Result: **UNTESTED**

### MFA settings
- Enrollment instructions and token input are labeled.
- Recovery-code warning is understandable.
- Disable-MFA confirmation is keyboard usable.
- Recovery-code presentation can be navigated/read reliably.

Result: **UNTESTED**

### Active sessions
- Current/other/revoked session states are understandable.
- Revoke controls are individually identifiable.
- Confirmation behavior is keyboard accessible.

Result: **UNTESTED**

### Audit history
- Event rows are navigable and understandable.
- Filters/pagination are labeled.
- Raw action identifiers do not replace human-readable descriptions.

Result: **UNTESTED**

## Reflow and zoom

Check at minimum:
- 200% browser zoom;
- narrow mobile-width viewport;
- no horizontal scrolling for ordinary page content except where genuinely required;
- controls do not overlap or become unreachable;
- text is not clipped.

Result: **UNTESTED**

## Screen-reader smoke

If a screen reader is available, record:
- page title/primary heading;
- landmark navigation;
- form labels and errors;
- button/control names and state;
- dynamic feedback after reveal/copy/revoke actions.

Result: **UNTESTED**

## Evidence boundary

Automated accessibility tests may remain PASS while this worksheet is still PENDING. Do not set `ux_accessibility_manual_status=pass` until the human review above has been completed and evidence has been recorded.

Final human-review status: **PENDING**
Formal WCAG conformance claimed: **NO**
