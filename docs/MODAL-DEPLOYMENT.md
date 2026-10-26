# Modal: separate public demo and private vault

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](MODAL-DEPLOYMENT.vi.md)

This document describes the **staging candidate**, not a statement that private production has passed disaster-recovery acceptance. Both deployments execute the same Rails application with `RAILS_ENV=production`. They must be separate Modal Environments, Apps, Secrets, database identities, and cryptographic keys.

## Mode matrix

| Policy | Public demo | Private vault |
| --- | --- | --- |
| Deployment selector | `REVAULT_MODAL_MODE=demo` | `REVAULT_MODAL_MODE=private` |
| Modal Environment | `rails-8-envelope-encryption-vault` | `ruby-envelope-private` |
| Modal App | `vault-demo` | `ruby-envelope-vault-private` |
| `PRODUCTION_POSTGRES_URL` | Must be absent | Mandatory |
| Database | PostgreSQL launched in the web container | User-provided external PostgreSQL with TLS |
| Restart/cold start | Entire database may be lost | PostgreSQL retains the data |
| Rails fixture | Synthetic `demo:fixture` | Never seeded automatically |
| Login & policies | Shared synthetic demo, no signups, MFA optional | Private owner, no signups, MFA required |
| KEK | Separate demo-only Modal Secret | Separate stable private Modal Secret and independent recovery custody |

A missing private URL **fails closed** and never triggers ephemeral local PostgreSQL. An unexpected external URL in demo mode **fails closed**. Both apps are limited to `max_containers=1`; local PostgreSQL binds only to `127.0.0.1`. Demo Redis and PostgreSQL use no persistent Modal Volume. `min_containers=0` permits cold starts and data resets.

## Configure Modal

Use two dedicated Modal Environments, distinct from the existing `ruby-envelope-staging`:

```sh
modal environment create rails-8-envelope-encryption-vault
modal environment create ruby-envelope-private
```

Create *separate* secrets in each Environment (use the Modal UI or `modal secret create --from-dotenv` with protected 0600 local files **outside Git**). Do not provide secret values as CLI arguments or commit their files:

| Modal secret name | Required variables |
| --- | --- |
| `rails-8-envelope-encryption-vault-crypto` | `VAULT_KEK_B64` (base64 of exactly 32 random bytes), `VAULT_ACTIVE_KEK_ID` |
| `rails-8-envelope-encryption-vault-runtime` | `SECRET_KEY_BASE` (>=64 bytes), `APP_HOSTS` (actual demo hostname), `DEMO_PASSWORD` (>=14 characters, deliberately public only for this synthetic demo) |
| `ruby-envelope-private-crypto` | Its own `VAULT_KEK_B64`, `VAULT_ACTIVE_KEK_ID` |
| `ruby-envelope-private-runtime` | Its own `SECRET_KEY_BASE`, `APP_HOSTS` (actual private hostname), **`PRODUCTION_POSTGRES_URL`** |

These keys **must never be shared** across demo, staging, and private environments. Keep a separately controlled copy of the private KEK. The private URL must contain credentials for a dedicated database/user and use TLS; `sslmode=require` is added if no mode was supplied. `sslmode=disable/prefer/allow` is rejected. Prefer `sslmode=verify-full` and the provider's CA for validated server identity.

`APP_HOSTS` must match the exact Modal-generated hostname or private domain. For initial setup, obtain the generated endpoint from `modal deploy`; if the host changes, update the relevant Secret and redeploy. Never disable Rails host or CSRF protection to work around an incorrect hostname.

## Recover the public demo login at any time

Visitors can change the shared demo password, enroll MFA, or consume recovery codes. To avoid locking out the next reviewer, the public sign-in page provides **Reset demo password & MFA**. This CSRF-protected POST action restores the configured demo password, deletes the demo account's enabled/pending TOTP setting and recovery codes, and revokes every session of that account. The action **does not erase synthetic Vault items**. It is rate-limited per IP and globally to reduce reset storms; any reset signs out other visitors. A fresh ephemeral container also recreates the demo baseline.

The reset is gated by `DEMO_MODE=true`, `SHOW_PUBLIC_DEMO_CREDENTIALS=true`, `PUBLIC_DEMO_RESET_ENABLED=true`, a fixed synthetic account, no registrations, and `REQUIRE_MFA=false`. The Modal demo bootstrap enables this feature; private bootstrap removes all corresponding demo variables and the same reset URL returns HTTP 404. Never publish private account recovery through this endpoint.

## Deploy

From the reviewed repo root, after installing and authenticating the Modal CLI:

```sh
python3 -m unittest discover -s ops/modal/tests -v
REVAULT_MODAL_MODE=demo modal deploy -e rails-8-envelope-encryption-vault ops/modal/app.py
REVAULT_MODAL_MODE=private modal deploy -e ruby-envelope-private ops/modal/app.py
```

**Private deployment must not be executed** until the external PostgreSQL database, private owner bootstrap, stable secret keys, backup, offsite recovery, and access-control plan are prepared. Private boot runs `db:migrate` (not `db:prepare` or `demo:fixture`) and never creates a database automatically. The owner must be provisioned separately through the existing guarded `vault:owner:create` workflow against the private database.

The external URL is a *Secret*, not part of Git, the notebook, a query string in the browser, or printed logs. Changing `PRODUCTION_POSTGRES_URL` points the app at a **different** database; do not treat that as data migration. When changing the key material, preserve the required historical KEKs and verify decrypt/recovery.

## Operational acceptance

For demo, verify `/ready`, `/session/new`, login with the deliberately synthetic account `showcase@example.test`, Vault/Audit/Sessions, mobile UX and database reset after a cold start. Share no real credentials or data; visitors use the same demo account.

For private, require HTTPS/host validation, TOTP MFA, session revocation, explicit reveal reauthentication, production security checks, `script/production-acceptance`, offsite encrypted backups, a fresh restore + exact fake-canary decrypt, and monitoring. An external PostgreSQL URL **only** solves database persistence: neither private KEK recovery nor backup/DR is automatic. Follow [Production checklist](PRODUCTION-CHECKLIST.md).

After validation and successful CI, update `v1.0.0` to the reviewed release source commit using a guarded tag replacement; never move the tag before source acceptance.
