# Ruby Envelope Vault
## MASTER IMPLEMENTATION PLAN — v1.0

**Document date:** 2026-09-27  
**Working repository name:** `ruby-envelope-vault`  
**Purpose:** a production-deployable Ruby on Rails personal secrets vault that demonstrates and uses envelope encryption correctly.

---

## 1. Product goal

Build a modern web application that can safely store and later reveal sensitive data such as:

- login passwords;
- API keys and access tokens;
- `.env` / environment secrets;
- database credentials;
- secure notes;
- SSH-related secrets or text credentials;
- arbitrary structured secret fields.

The application must be useful as a real personal vault, while also being strong enough as a portfolio/project showcase.

The primary security property is:

> A PostgreSQL dump by itself must not be sufficient to recover stored vault secrets.

The application achieves this by encrypting every secret payload with a random Data Encryption Key (DEK), then wrapping that DEK with a separate Key Encryption Key (KEK).

---

## 2. Baseline technology decisions

### Production baseline

- Ruby: **3.4.11**
- Rails: **8.1.4**
- PostgreSQL: **17.x**
- Puma
- Hotwire: Turbo + Stimulus
- Tailwind CSS v4 through `tailwindcss-rails`
- Propshaft / Rails defaults
- Rails 8 authentication generator
- Minitest
- Docker
- Kamal
- GitHub Actions
- Brakeman
- bundler-audit

### Compatibility CI

In addition to the production Ruby version, run a non-blocking or secondary CI job on the current Ruby 4.0.x branch.

### Why Ruby 3.4.11 for the first production baseline

Ruby 3.4 and Ruby 4.0 are both under normal maintenance as of this document. The first release should optimize for a predictable deployment environment rather than maximizing version novelty. Once CI is green on Ruby 4.0, upgrading production should be a routine change rather than a redesign.

### PostgreSQL choice

Use PostgreSQL 17 for the first production image. PostgreSQL 18 is supported and may be adopted later, but no v1 feature requires it.

### No Node.js requirement

Use `tailwindcss-rails` v4, which relies on `tailwindcss-ruby`. Keep the default Rails importmap/Hotwire approach. The v1 application should not require Node.js/npm just to build the frontend.

---

## 3. Explicit non-goals for v1.0

Do **not** expand v1.0 into all of the following:

- zero-knowledge cryptography;
- browser extensions;
- mobile applications;
- multi-tenant organizations;
- team secret sharing;
- public secret-sharing links;
- SSH agent functionality;
- password autofill;
- automatic AWS/GCP/Azure secret synchronization;
- encrypted full-text search;
- public REST API;
- passkey-only authentication.

These are possible v2+ features.

---

## 4. Security invariants

The implementation is not considered complete unless all of these invariants remain true.

1. Application login passwords are **hashed**, never reversibly encrypted.
2. Vault payloads are encrypted before persistence.
3. Every vault-item version receives a fresh random 256-bit DEK.
4. AES-256-GCM is used as the application AEAD cipher.
5. A fresh 96-bit GCM nonce is generated for each data-encryption operation.
6. A 128-bit authentication tag is required and validated on decrypt.
7. A `(key, nonce)` pair must never be reused.
8. The DEK is never stored plaintext.
9. The KEK is never stored in PostgreSQL.
10. The Rails master key and Vault KEK are separate secrets.
11. PostgreSQL never stores plaintext title, username, password, token, note body, `.env` values, or custom secret fields.
12. No plaintext secret is written into Rails logs, audit logs, exception messages, URLs, analytics, or background-job arguments.
13. Tampered ciphertext, tag, nonce, AAD, or wrapped DEK fails closed.
14. A KEK rotation changes the wrapped DEK but does not require changing the data ciphertext.
15. Backup and restore are not accepted as working until a fresh restore can decrypt a known test secret.
16. Ruby code must not claim guaranteed memory zeroization. Ruby/GC does not provide a dependable general-purpose zeroization guarantee; instead, minimize plaintext/key lifetime and avoid unnecessary copies.

---

## 5. Threat model

### v1 is designed to reduce damage from

- stolen PostgreSQL dump;
- leaked DB backup;
- read-only DB compromise;
- accidental SQL inspection;
- lost database snapshot;
- ciphertext modification/tampering;
- reuse of an old database copy after a key rotation;
- accidental logging of submitted secrets.

### v1 does not fully protect against

- full compromise of the running Rails host while it can access the KEK;
- malicious code executing inside the Rails process;
- compromised browser/device;
- keylogger or malicious browser extension;
- administrator intentionally reading secrets from a live authorized application process;
- simultaneous compromise of DB + KEK provider/host.

This is **server-side envelope encryption**, not a zero-knowledge password manager.

---

# 6. High-level architecture

```text
 Browser
    |
 HTTPS
    |
    v
 Rails / Puma
    |
    +---------------------------+
    |                           |
    v                           v
Vault services              PostgreSQL
    |                       ciphertext
    |                       nonce
    v                       auth tag
EnvelopeEncryptor           wrapped DEK
    |
    v
KeyProvider
    |
    +--> LocalFileKeyProvider (v1)
    |
    +--> AWS KMS / GCP KMS / Azure Key Vault (future adapters)
```

Crypto flow:

```text
plaintext JSON
    |
    | fresh random 32-byte DEK
    v
AES-256-GCM
    |
    +--> ciphertext
    +--> 12-byte nonce
    +--> 16-byte auth tag

DEK
    |
    | KeyProvider.wrap_key
    v
wrapped DEK
```

Database receives only the encrypted envelope and non-secret routing metadata.

---

# 7. Bootstrap from an empty machine

Assuming Ruby 3.4.11 is already activated:

```bash
gem install rails -v 8.1.4

rails _8.1.4_ new ruby-envelope-vault \
  --database=postgresql \
  --css=tailwind \
  --primary-key-type=uuid

cd ruby-envelope-vault

bin/setup
```

If using `mise`:

```bash
mise use ruby@3.4.11
ruby -v

gem install rails -v 8.1.4

rails _8.1.4_ new ruby-envelope-vault \
  --database=postgresql \
  --css=tailwind \
  --primary-key-type=uuid
```

Then initialize Git immediately:

```bash
git add .
git commit -m "Bootstrap Rails 8.1 envelope vault"
```

---

# 8. Gem plan

Keep dependencies deliberately small.

## Runtime

```ruby
gem "rails", "~> 8.1.4"
gem "pg"
gem "puma"
gem "tailwindcss-rails", "~> 4.0"
gem "bcrypt"
gem "rack-attack"
```

Rails/Hotwire defaults provide Turbo and Stimulus.

## Security/development

```ruby
group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end
```

Keep the Rails default RuboCop setup.

## MFA milestone

Add only when implementing MFA:

```ruby
gem "rotp"
gem "rqrcode"
```

Do not add cloud KMS SDKs until an adapter actually exists.

---

# 9. Authentication plan

Run:

```bash
bin/rails generate authentication
bin/rails db:migrate
```

Rails authentication is the baseline for:

- `User`;
- `Session`;
- login/logout;
- reset-password flow.

Add a small registration flow separately.

## Production signup policy

For a personal vault:

```text
ALLOW_SIGNUPS=false
```

The application must support creating the initial owner through a Rails task or console and then disabling registration.

For a public portfolio demo:

```text
DEMO_MODE=true
ALLOW_SIGNUPS=false
```

Only fake/demo secrets must exist in that public instance.

Do not use the public showcase instance as the personal production vault.

---

# 10. Database design

All application primary keys use PostgreSQL UUIDs.

## 10.1 `users`

Generated by Rails authentication and extended as required.

Conceptual fields:

```text
id uuid
email_address
password_digest
created_at
updated_at
```

Never envelope-encrypt `password_digest`. It is a one-way password hash.

---

## 10.2 `sessions`

Use the Rails authentication-generated session table.

Optionally extend with:

```text
ip_hash
user_agent_summary
last_seen_at
revoked_at
```

Do not store more device data than needed.

---

## 10.3 `vault_items`

Contains ownership and non-secret state only.

```text
id uuid PK
user_id uuid FK NOT NULL
kind varchar NOT NULL
favorite boolean NOT NULL DEFAULT false
archived_at timestamptz NULL
current_version_id uuid NULL
created_at
updated_at
```

Allowed `kind` values:

```text
login
api_key
environment
database
secure_note
ssh
generic
```

Do not add plaintext columns such as:

```text
title
username
password
url
notes
api_key
environment_value
```

Indexes:

```text
(user_id)
(user_id, kind)
(user_id, archived_at)
(user_id, favorite)
```

---

## 10.4 `vault_item_versions`

This is the encrypted-data table.

```text
id uuid PK
vault_item_id uuid FK NOT NULL
version_number integer NOT NULL

envelope_version integer NOT NULL DEFAULT 1
payload_format varchar NOT NULL DEFAULT 'json.v1'
cipher_suite varchar NOT NULL DEFAULT 'AES-256-GCM'

ciphertext bytea NOT NULL
nonce bytea NOT NULL
authentication_tag bytea NOT NULL

key_provider varchar NOT NULL
kek_id varchar NOT NULL
wrapped_dek bytea NOT NULL

aad_version integer NOT NULL DEFAULT 1

created_by_user_id uuid FK NOT NULL
created_at timestamptz NOT NULL
```

Constraints:

```sql
CHECK (octet_length(nonce) = 12)
CHECK (octet_length(authentication_tag) = 16)
CHECK (octet_length(ciphertext) > 0)
CHECK (octet_length(wrapped_dek) > 0)
CHECK (version_number > 0)
CHECK (envelope_version > 0)
CHECK (aad_version > 0)
```

Unique index:

```text
(vault_item_id, version_number)
```

After this table exists, add the foreign key:

```text
vault_items.current_version_id
  -> vault_item_versions.id
```

The application must verify that `current_version_id` belongs to the same `vault_item`.

---

## 10.5 `key_registries`

Metadata only. Never key bytes.

```text
id uuid PK
provider varchar NOT NULL
kek_id varchar NOT NULL
status varchar NOT NULL
activated_at timestamptz
retired_at timestamptz
created_at
updated_at
```

Allowed status:

```text
pending
active
decrypt_only
retired
```

Unique:

```text
(provider, kek_id)
```

No secret material belongs in this table.

---

## 10.6 `audit_events`

```text
id uuid PK
user_id uuid NULL
vault_item_id uuid NULL
action varchar NOT NULL
request_id varchar
metadata jsonb NOT NULL DEFAULT '{}'
created_at timestamptz NOT NULL
```

Example actions:

```text
user.login_succeeded
user.login_failed
user.logout

vault_item.created
vault_item.updated
vault_item.revealed
vault_item.copied
vault_item.archived
vault_item.restored
vault_item.deleted

vault_export.created

key.rotation_started
key.rotation_completed
key.rotation_failed
```

Audit metadata may contain identifiers and safe status data only.

Never log:

- plaintext payload;
- passwords;
- tokens;
- API keys;
- DEKs;
- KEKs;
- complete `.env` values;
- wrapped-key debug dumps.

Make `AuditEvent` append-only at the model layer. Consider a DB trigger/privilege split later if stronger immutability is required.

---

# 11. Encrypted payload format

The application encrypts one canonical JSON document per version.

Example login payload:

```json
{
  "schema": "vault.login.v1",
  "title": "Production PostgreSQL",
  "username": "backup_user",
  "password": "secret",
  "url": "postgres.example.internal",
  "notes": "Primary production database",
  "tags": ["postgres", "production"],
  "custom_fields": []
}
```

Example environment payload:

```json
{
  "schema": "vault.environment.v1",
  "title": "Rails production",
  "environment": "production",
  "entries": [
    {"key": "DATABASE_URL", "value": "..."},
    {"key": "OPENAI_API_KEY", "value": "..."}
  ],
  "notes": ""
}
```

Canonicalization rules:

1. UTF-8.
2. JSON object only.
3. Schema string required.
4. Strict maximum payload size.
5. Normalize line endings where appropriate.
6. Do not compute or store a plaintext SHA-256 hash for duplicate detection; that can leak equality information.

Suggested first payload limit:

```text
1 MiB plaintext per version
```

This can be increased deliberately later.

---

# 12. AAD design

Use authenticated associated data so ciphertext cannot be copied into another user/item/version without detection.

`AAD v1` is deterministic:

```text
ruby-envelope-vault
envelope=1
aad=1
user=<user UUID>
item=<vault item UUID>
version=<vault item version UUID>
```

Serialize in one canonical form, for example:

```text
ruby-envelope-vault|e=1|a=1|u=<uuid>|i=<uuid>|v=<uuid>
```

Rules:

- UUIDs are created before encryption.
- AAD is not secret.
- AAD must never depend on mutable fields.
- The same builder is used for encryption and decryption.
- Changing user/item/version association must make authentication fail.

File:

```text
app/services/crypto/aad_builder.rb
```

API:

```ruby
Crypto::AadBuilder.call(
  envelope_version:,
  aad_version:,
  user_id:,
  vault_item_id:,
  vault_item_version_id:
)
```

---

# 13. Core cryptographic classes

Create:

```text
app/services/crypto/
├── aad_builder.rb
├── envelope.rb
├── envelope_encryptor.rb
├── errors.rb
└── payload_serializer.rb
```

## 13.1 `Crypto::Envelope`

Plain Ruby value object.

Fields:

```text
envelope_version
payload_format
cipher_suite
ciphertext
nonce
authentication_tag
key_provider
kek_id
wrapped_dek
aad_version
```

It must validate lengths and required metadata before decrypt is attempted.

---

## 13.2 `Crypto::PayloadSerializer`

Responsibilities:

```text
Ruby Hash -> canonical UTF-8 JSON
JSON -> validated Hash
```

Do not place encryption logic here.

---

## 13.3 `Crypto::EnvelopeEncryptor`

Public API:

```ruby
Crypto::EnvelopeEncryptor.encrypt(
  plaintext:,
  context:,
  key_provider:
)
```

and:

```ruby
Crypto::EnvelopeEncryptor.decrypt(
  envelope:,
  context:,
  key_provider:
)
```

Encryption algorithm:

```text
1. Validate context.
2. Generate 32 random bytes with OpenSSL::Random.random_bytes(32).
3. Generate 12 random nonce bytes.
4. Build AAD.
5. Initialize OpenSSL AES-256-GCM.
6. Set key.
7. Set IV/nonce.
8. Set AAD.
9. Encrypt.
10. Finalize.
11. Read 16-byte auth tag.
12. Ask KeyProvider to wrap DEK.
13. Return immutable Envelope.
14. Drop references to plaintext DEK as soon as practical.
```

Decryption:

```text
1. Validate envelope structure.
2. Resolve key provider and KEK id.
3. Unwrap DEK.
4. Rebuild the exact AAD.
5. Initialize AES-256-GCM decrypt.
6. Set DEK.
7. Set nonce.
8. Set 16-byte auth tag.
9. Set AAD.
10. Decrypt and finalize.
11. If authentication fails, raise Crypto::AuthenticationError.
12. Never return partial plaintext.
```

Do not rescue a cryptographic authentication failure and continue.

---

# 14. Crypto error hierarchy

`app/services/crypto/errors.rb`:

```ruby
module Crypto
  class Error < StandardError; end
  class InvalidEnvelopeError < Error; end
  class AuthenticationError < Error; end
  class UnknownKeyProviderError < Error; end
  class UnknownKeyError < Error; end
  class KeyWrapError < Error; end
  class KeyUnwrapError < Error; end
  class UnsupportedEnvelopeVersionError < Error; end
end
```

Controller responses must not expose internal crypto details.

User-facing example:

```text
This secret could not be decrypted.
```

Log only safe identifiers and error class.

---

# 15. Key-provider abstraction

Create:

```text
app/services/key_providers/
├── base.rb
├── registry.rb
└── local_file.rb
```

Interface:

```ruby
class KeyProviders::Base
  def provider_name
    raise NotImplementedError
  end

  def active_key_id
    raise NotImplementedError
  end

  def wrap_key(dek:, context:)
    raise NotImplementedError
  end

  def unwrap_key(wrapped_key:, key_id:, context:)
    raise NotImplementedError
  end
end
```

A wrapped key is treated as an **opaque blob** by `EnvelopeEncryptor`.

This is important: provider-specific nonce/tag structures must not leak into the vault schema.

---

# 16. LocalFileKeyProvider

v1 provider:

```text
KeyProviders::LocalFile
```

Configuration:

```text
VAULT_KEY_PROVIDER=local_file
VAULT_ACTIVE_KEK_ID=kek-2026-01
VAULT_KEK_DIR=/run/secrets/ruby-envelope-vault/keks
```

Example filesystem:

```text
/run/secrets/ruby-envelope-vault/keks/
├── kek-2026-01.key
└── kek-2027-01.key
```

Permissions:

```text
directory: 0700
key files: 0600 or stricter
```

Each KEK is exactly 32 random bytes.

Do not encode the KEK into source code.

Do not place KEK files inside the Git repository.

Do not use `RAILS_MASTER_KEY` as the Vault KEK.

## Local wrapping cipher

Use AES-256-GCM again for DEK wrapping, with:

- KEK = 32 bytes;
- independent random 12-byte wrapping nonce;
- 16-byte wrapping auth tag;
- wrapping AAD bound to provider, KEK id, item id and version id.

The provider returns one opaque serialized blob.

Suggested logical blob:

```json
{
  "v": 1,
  "alg": "A256GCM",
  "iv": "<base64url>",
  "tag": "<base64url>",
  "ct": "<base64url>"
}
```

Serialize to bytes before storing in `wrapped_dek`.

Validate all decoded sizes strictly.

---

# 17. Key-provider registry

`KeyProviders::Registry` maps names to implementations.

Example:

```ruby
KeyProviders::Registry.fetch("local_file")
```

Future:

```text
aws_kms
gcp_kms
azure_key_vault
hashicorp_vault
```

No model/controller should instantiate cloud SDKs directly.

---

# 18. Key lifecycle and rotation

Provide Rake/CLI tasks:

```bash
bin/rails vault:keys:generate ID=kek-2026-01
bin/rails vault:keys:list
bin/rails vault:keys:verify
bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01 DRY_RUN=1
bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01
```

Rotation algorithm:

```text
for each version using old KEK:
  unwrap DEK using old KEK
  wrap same DEK using new KEK
  update wrapped_dek + kek_id atomically
  never alter ciphertext/nonce/authentication_tag
```

Safety properties:

- batch operation;
- resumable;
- idempotent where practical;
- advisory lock to prevent two rotations at once;
- progress counters;
- audit event;
- dry-run;
- old key remains `decrypt_only` until verification completes.

Verification after rotation:

```text
records_before == records_after
ciphertext hashes unchanged
all records reference expected KEK
sample/full decrypt verification PASS
```

Only after successful verification can an old key be retired.

Never automatically delete the old KEK during the same rotation command.

---

# 19. Vault application services

Create:

```text
app/services/vault/
├── create_item.rb
├── update_item.rb
├── reveal_item.rb
├── restore_version.rb
├── archive_item.rb
├── delete_item.rb
└── export_item.rb
```

Controllers call these services rather than manipulating crypto columns directly.

Example:

```ruby
Vault::CreateItem.call(
  user: Current.user,
  kind:,
  payload:
)
```

`CreateItem` flow:

```text
transaction
  create VaultItem UUID
  pre-generate VaultItemVersion UUID
  serialize payload
  encrypt with context
  persist version
  set current_version_id
  append audit event
commit
```

`UpdateItem` never overwrites the previous version.

It creates a new immutable encrypted version.

---

# 20. Model responsibilities

## `VaultItem`

Responsible for:

- ownership;
- kind;
- archive/favorite state;
- current version association.

Not responsible for OpenSSL calls.

## `VaultItemVersion`

Responsible for:

- envelope persistence;
- structural validation;
- immutable version semantics.

Not responsible for controllers/UI.

After creation, encrypted fields should be treated as immutable except the KEK-wrapping fields during an explicit key rotation.

## `KeyRegistry`

Metadata only.

## `AuditEvent`

Append-only event representation.

---

# 21. Controller plan

Create:

```text
app/controllers/
├── dashboard_controller.rb
├── registrations_controller.rb
├── vault_items_controller.rb
├── vault_item_versions_controller.rb
├── vault_reveals_controller.rb
├── vault_exports_controller.rb
├── audit_events_controller.rb
└── settings/
    ├── security_controller.rb
    └── sessions_controller.rb
```

Controllers must remain thin.

---

# 22. Route plan

Conceptual routes:

```ruby
root "dashboard#show"

resource :registration, only: %i[new create]

resources :vault_items do
  member do
    post :archive
    post :unarchive
  end

  resources :versions,
            controller: "vault_item_versions",
            only: %i[index show] do
    member do
      post :restore
    end
  end

  resource :reveal,
           controller: "vault_reveals",
           only: :create

  resource :export,
           controller: "vault_exports",
           only: %i[new create]
end

resources :audit_events, only: :index

namespace :settings do
  resource :security, only: %i[show update]
  resources :sessions, only: %i[index destroy]
end
```

Sensitive reveal/export operations should use non-cacheable responses and CSRF-protected state-changing requests.

Do not place plaintext secret values in query strings.

---

# 23. Reveal flow

Vault list/details initially show masked values.

Example:

```text
Password
••••••••••••••
[Reveal] [Copy]
```

`POST /vault_items/:id/reveal`:

1. authenticate user;
2. authorize ownership;
3. optionally require recent reauthentication;
4. decrypt;
5. append safe audit event;
6. return Turbo/HTML fragment or JSON with strict `Cache-Control: no-store`;
7. UI auto-hides the value.

Do not put plaintext into:

- URL;
- flash message;
- server log;
- DOM `data-*` attributes that persist beyond need;
- analytics event.

For highly sensitive fields, render only when requested.

---

# 24. `.env` vault UX

The environment editor is a first-class v1 feature.

Input supports:

```text
DATABASE_URL=...
OPENAI_API_KEY=...
HF_TOKEN=...
```

Parser must handle:

- blank lines;
- comments;
- quoted values;
- `=` inside values;
- UTF-8;
- duplicate key warning;
- line numbers for parse errors.

Encrypted payload stores structured entries.

UI:

```text
DATABASE_URL       ••••••••••   Reveal  Copy
OPENAI_API_KEY     ••••••••••   Reveal  Copy
HF_TOKEN           ••••••••••   Reveal  Copy
```

Actions:

```text
Copy selected value
Copy complete .env
Download .env
```

`.env` download:

- stream response;
- do not write plaintext temp files on server;
- `Cache-Control: no-store`;
- attachment response;
- audit event;
- optional recent-password confirmation.

---

# 25. Reauthentication

A logged-in session alone should not authorize every destructive/sensitive operation forever.

Track:

```text
session.reauthenticated_at
```

Require recent password confirmation for:

- plaintext bulk export;
- deleting a vault item permanently;
- rotating/replacing user security settings;
- viewing recovery codes;
- disabling MFA.

Recommended window:

```text
5 minutes
```

A normal single-secret reveal can initially use the authenticated session; optionally make this configurable.

---

# 26. Rate limiting

Use `rack-attack` or equivalent Rails-native throttling where practical.

At minimum throttle:

- login attempts;
- password reset requests;
- registration;
- MFA verification;
- reauthentication.

Do not create a rate limit that leaks whether a specific email address exists.

---

# 27. MFA milestone

After the core vault is stable, add TOTP.

Tables:

```text
user_mfa_settings
recovery_codes
```

TOTP seed is itself sensitive and must be envelope-encrypted.

Recovery codes are generated once and only their password-style hashes are stored.

MFA setup flow:

```text
generate seed
show QR
require successful OTP confirmation
persist encrypted seed
generate recovery codes
show once
```

MFA is a prerequisite for declaring a public-facing personal deployment “production hardened”.

---

# 28. UI information architecture

Desktop:

```text
┌──────────────────────────────────────────────────────────┐
│ Envelope Vault                             Account       │
├──────────────┬───────────────────────────────────────────┤
│ Dashboard    │ Search                                    │
│ All items    │                                           │
│ Logins       │  Production DB                  ★         │
│ API keys     │  GitHub token                            │
│ ENV          │  Rails production                        │
│ Notes        │                                           │
│ Databases    │                                           │
│ Archived     │                                           │
│              │                              + New secret │
│ Audit        │                                           │
│ Settings     │                                           │
└──────────────┴───────────────────────────────────────────┘
```

Mobile:

```text
top bar
search
cards
floating create button
bottom navigation
```

Required pages:

1. landing/login;
2. dashboard;
3. all items;
4. category filter;
5. create secret;
6. edit secret;
7. secret detail;
8. version history;
9. audit log;
10. security/session settings;
11. backup/security documentation page for owner.

Use an accessible modal/dialog only where appropriate.

---

# 29. Search strategy for v1

Do not implement searchable encryption in v1.

Because sensitive titles remain encrypted, the server may decrypt the authenticated user's small personal-vault dataset in memory and filter the display/search result.

This is acceptable for a personal vault with hundreds or low thousands of records.

If scale later demands indexes, design a separate blind-index/HMAC threat model rather than storing plaintext search columns casually.

---

# 30. Log hygiene

Configure:

```ruby
config.filter_parameters += [
  :password,
  :password_confirmation,
  :secret,
  :token,
  :api_key,
  :private_key,
  :credential,
  :plaintext,
  :environment,
  :value
]
```

Also inspect custom logs.

Structured logging may contain:

```text
request_id
user_id
vault_item_id
event
duration_ms
status
error_class
```

It must not contain payload data.

Add automated tests with known canary secrets:

```text
SUPER_SECRET_CANARY_DO_NOT_LOG
```

Run actions and assert that the canary string never appears in captured logs.

---

# 31. HTTP/browser hardening

Production requirements:

- HTTPS only;
- HSTS;
- secure cookies;
- HttpOnly session cookies;
- appropriate SameSite policy;
- CSRF protection;
- Content-Security-Policy;
- `X-Content-Type-Options`;
- conservative `Referrer-Policy`;
- no third-party analytics on authenticated vault pages;
- no third-party JavaScript on secret pages;
- prefer locally served assets/fonts.

Sensitive responses:

```text
Cache-Control: no-store
Pragma: no-cache
```

as appropriate.

---

# 32. Cryptographic test matrix

Create:

```text
test/services/crypto/
├── aad_builder_test.rb
├── envelope_encryptor_test.rb
├── envelope_validation_test.rb
└── local_file_key_provider_test.rb
```

Mandatory cases:

| Test | Expected |
|---|---|
| encrypt -> decrypt | exact original |
| encrypt same plaintext twice | different ciphertext |
| tamper ciphertext | fail |
| tamper nonce | fail |
| tamper auth tag | fail |
| wrong AAD user id | fail |
| wrong AAD item id | fail |
| wrong AAD version id | fail |
| wrong KEK | fail |
| truncated GCM tag | reject |
| malformed wrapped-key blob | reject |
| unknown KEK id | fail |
| Unicode/Vietnamese payload | pass |
| multiline secure note | pass |
| `.env` with `=` in values | pass |
| near-max payload | pass |
| KEK rewrap | plaintext still decrypts |
| KEK rewrap | data ciphertext unchanged |

Use fixed deterministic fixtures only where necessary for parsing/compatibility tests. Production encryption always uses secure random values.

---

# 33. Model/service authorization tests

Mandatory cross-user tests:

```text
User A cannot:
- view User B item
- reveal User B item
- restore User B version
- export User B item
- archive/delete User B item
```

Do not rely only on hidden UUIDs as authorization.

Every query is scoped through the authenticated user.

---

# 34. System tests

Important browser-level flows:

```text
login
create login secret
reveal/hide
copy action UI state
edit -> creates new version
restore older version
archive/unarchive
create .env secret
download .env
logout
session cannot access vault
```

Add a production-like smoke test using real PostgreSQL rather than SQLite.

---

# 35. Security CI

Create `bin/ci`:

```bash
#!/usr/bin/env bash
set -euo pipefail

bin/rails db:test:prepare
bin/rails test
bin/rails test:system
bin/rubocop
bundle exec brakeman -q
bundle exec bundle-audit check --update
```

GitHub Actions stages:

```text
bundle/install
database
unit/integration tests
system tests
rubocop
brakeman
bundler-audit
```

Production baseline Ruby job is blocking.

Ruby 4.0 compatibility job can initially be allowed to fail only during bootstrap; make it blocking once clean.

---

# 36. Repository structure target

```text
ruby-envelope-vault/
├── app/
│   ├── controllers/
│   │   ├── dashboard_controller.rb
│   │   ├── registrations_controller.rb
│   │   ├── vault_items_controller.rb
│   │   ├── vault_item_versions_controller.rb
│   │   ├── vault_reveals_controller.rb
│   │   ├── vault_exports_controller.rb
│   │   ├── audit_events_controller.rb
│   │   └── settings/
│   │       ├── security_controller.rb
│   │       └── sessions_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── session.rb
│   │   ├── vault_item.rb
│   │   ├── vault_item_version.rb
│   │   ├── key_registry.rb
│   │   └── audit_event.rb
│   ├── services/
│   │   ├── crypto/
│   │   │   ├── aad_builder.rb
│   │   │   ├── envelope.rb
│   │   │   ├── envelope_encryptor.rb
│   │   │   ├── errors.rb
│   │   │   └── payload_serializer.rb
│   │   ├── key_providers/
│   │   │   ├── base.rb
│   │   │   ├── registry.rb
│   │   │   └── local_file.rb
│   │   └── vault/
│   │       ├── create_item.rb
│   │       ├── update_item.rb
│   │       ├── reveal_item.rb
│   │       ├── restore_version.rb
│   │       ├── archive_item.rb
│   │       └── export_item.rb
│   ├── javascript/controllers/
│   │   ├── reveal_controller.js
│   │   ├── clipboard_controller.js
│   │   └── secret_form_controller.js
│   └── views/
├── config/
│   ├── initializers/
│   │   ├── content_security_policy.rb
│   │   ├── filter_parameter_logging.rb
│   │   ├── rack_attack.rb
│   │   └── vault.rb
│   └── deploy.yml
├── db/
│   └── migrate/
├── lib/tasks/
│   ├── vault_keys.rake
│   └── vault_demo.rake
├── script/
│   ├── backup-db
│   ├── restore-db
│   └── verify-backup
├── test/
│   ├── controllers/
│   ├── models/
│   ├── services/
│   │   ├── crypto/
│   │   ├── key_providers/
│   │   └── vault/
│   └── system/
├── .github/workflows/ci.yml
├── Dockerfile
├── compose.yaml
├── README.md
├── SECURITY.md
├── THREAT-MODEL.md
├── BACKUP-RESTORE.md
└── KEY-MANAGEMENT.md
```

---

# 37. Required migrations in order

Use migration names roughly like:

```text
001_enable_pgcrypto.rb
002_authentication_generated_tables.rb
003_create_vault_items.rb
004_create_vault_item_versions.rb
005_add_current_version_to_vault_items.rb
006_create_key_registries.rb
007_create_audit_events.rb
008_add_session_security_fields.rb
009_create_mfa_tables.rb          # later milestone
```

Run schema validation tests against PostgreSQL.

---

# 38. Key-generation task

`vault:keys:generate` must:

1. require an explicit key id;
2. create 32 CSPRNG bytes;
3. use exclusive file creation;
4. refuse to overwrite an existing key;
5. chmod to `0600`;
6. print only path + key id + SHA-256 fingerprint;
7. never print key bytes.

Example output:

```text
Created KEK
id: kek-2026-01
path: /secure/.../kek-2026-01.key
fingerprint: sha256:...
permissions: 0600
```

A fingerprint can identify a key operationally without exposing its bytes.

---

# 39. Backup design

A DB dump still contains:

- encrypted vault payloads;
- wrapped DEKs;
- account email addresses;
- password hashes;
- audit metadata.

Therefore offsite DB backup should still be encrypted in transit/at rest.

Scripts:

```text
script/backup-db
script/verify-backup
script/restore-db
```

Recommended backup pipeline:

```text
pg_dump --format=custom
    |
    v
optional age encryption for portable offsite artifact
    |
    v
SHA-256 checksum
    |
    v
offsite storage
```

Do not place the KEK in the database backup.

Recovery materials are separate:

```text
A. encrypted PostgreSQL backup
B. Vault KEK recovery copy
C. Rails/Ruby application source/config
```

For LocalFileKeyProvider, keep at least one offline recovery copy of each still-needed KEK.

---

# 40. Backup acceptance test

A backup is not “verified” merely because `pg_dump` exited 0.

Required drill:

```text
1. Create known canary secret.
2. Produce DB backup.
3. Verify artifact checksum.
4. Start fresh PostgreSQL database.
5. Restore dump.
6. Start app with recovery KEK.
7. Log in.
8. Decrypt canary secret.
9. Verify version history.
10. Record PASS result.
```

Perform this before using the vault for important real secrets.

---

# 41. Docker design

Production image should be multi-stage.

Runtime contains only what is required by Rails plus PostgreSQL client utilities if backup scripts run inside the app container.

Do not `COPY` KEK files into the Docker image.

Mount/inject at runtime:

```text
/run/secrets/ruby-envelope-vault/keks
```

Docker image must be safe to push to a public registry without exposing:

- `RAILS_MASTER_KEY`;
- Vault KEKs;
- DB passwords;
- production `.env`.

---

# 42. Local compose profile

`compose.yaml`:

```text
web
postgres
```

Development key directory is host-mounted and gitignored.

Do not treat Docker Compose local configuration as the production secret-management design.

---

# 43. Kamal production deployment

Target:

```text
Internet
   |
 HTTPS
   |
Kamal Proxy / Rails
   |
   +------ PostgreSQL
   |
   +------ mounted KEK or KMS adapter
```

First deployment can use:

```bash
bin/kamal setup
```

Subsequent deploys:

```bash
bin/kamal deploy
```

Use health checks that verify app/database reachability without decrypting or exposing any vault secret.

---

# 44. Two deployment profiles

## A. Public portfolio demo

Purpose: recruiters/users can inspect UI/functionality.

Rules:

```text
DEMO_MODE=true
ALLOW_SIGNUPS=false
fake secrets only
no personal data
no personal KEK
safe demo account
```

Optionally reset demo data periodically.

## B. Personal production vault

Rules:

```text
DEMO_MODE=false
ALLOW_SIGNUPS=false
MFA enabled
unique domain
HTTPS
persistent PostgreSQL
separate KEK
tested backup
tested restore
```

Ideally do not host your real vault in the same deployment used as a public showcase.

---

# 45. Cheap production topology

For the lowest-cost real deployment:

```text
One small VPS
├── Rails container
├── PostgreSQL persistent volume
└── host-mounted KEK
```

This protects well against a DB-only dump leak but **not** against complete compromise of the VPS because data and usable KEK access exist on the same machine.

Stronger architecture:

```text
Rails VPS
   |
   +--> managed PostgreSQL
   |
   +--> external KMS
```

That should be the later “production hardened” showcase tier.

---

# 46. Cloud KMS adapter contract

Do not implement until LocalFile provider is complete and tested.

Future adapters must preserve:

```ruby
wrap_key(dek:, context:)
unwrap_key(wrapped_key:, key_id:, context:)
```

For cloud KMS:

- `wrapped_key` is the opaque KMS ciphertext blob;
- `kek_id` is the KMS key/resource identifier alias stored safely;
- encryption context/AAD should bind app/item/version where provider supports it;
- Rails never receives raw KEK material.

No database migration should be needed merely to add a new provider.

---

# 47. Version compatibility policy

Store:

```text
envelope_version
aad_version
payload_format
cipher_suite
key_provider
kek_id
```

Never infer crypto behavior solely from “current code”.

Decryption dispatches by persisted version.

This permits future migration:

```text
Envelope v1 -> v2
JSON v1 -> v2
Local key provider -> KMS
```

without making old records unreadable.

---

# 48. Crypto migration rule

Do not silently rewrite every record during a normal web request.

Large migrations should be explicit maintenance operations:

```text
dry run
batch
checkpoint
resume
verify
report
```

Keep old decrypt support until migration verification completes.

---

# 49. README plan

README sections:

1. What this project is.
2. Screenshots.
3. Why envelope encryption.
4. Architecture diagram.
5. Threat model summary.
6. Quick local start.
7. Generate first KEK.
8. Create owner.
9. Store first secret.
10. Inspect PostgreSQL proof.
11. Key rotation.
12. Backup.
13. Restore.
14. Docker.
15. Production deployment.
16. Security assumptions.
17. Development/test commands.
18. Roadmap.

A showcase section should prove:

```text
same plaintext -> different ciphertext
tampered ciphertext -> decrypt fails
DB dump -> no plaintext vault payload
KEK rotation -> ciphertext unchanged
fresh restore -> secret decrypts
```

---

# 50. `SECURITY.md`

Must document:

- supported versions;
- how to report vulnerabilities;
- no real secrets in bug reports;
- cryptographic scope;
- deployment assumptions;
- responsible disclosure contact/process;
- warning that the demo instance contains fake data only.

---

# 51. `THREAT-MODEL.md`

Must explicitly list:

```text
assets
trust boundaries
attackers
protected scenarios
out-of-scope scenarios
key locations
DB locations
backup locations
browser risks
server-compromise limitation
```

This file is part of the portfolio value, not optional documentation.

---

# 52. Implementation milestones

## M0 — Bootstrap

Deliver:

```text
Rails 8.1.4
Ruby 3.4.11
PostgreSQL
Tailwind
Hotwire
UUID primary keys
CI
Docker development
```

Acceptance:

```text
bin/rails test -> PASS
Tailwind builds
PostgreSQL connection works
CI green
```

---

## M1 — Authentication

Deliver:

```text
Rails auth generator
registration control
login/logout
reset password
session management
owner creation task
ALLOW_SIGNUPS
```

Acceptance:

```text
anonymous cannot access vault
cross-user access denied
password hashes only
```

---

## M2 — Crypto core

Deliver:

```text
Envelope
AadBuilder
PayloadSerializer
EnvelopeEncryptor
Crypto errors
LocalFileKeyProvider
Key registry
key generate/list/verify tasks
```

Acceptance:

**All crypto tests pass before vault CRUD development continues.**

---

## M3 — Vault CRUD with immutable versions

Deliver:

```text
VaultItem
VaultItemVersion
CreateItem
UpdateItem
RevealItem
RestoreVersion
archive
favorite
```

Acceptance:

```text
create -> decrypt PASS
edit -> old version preserved
restore -> new/current state correct
SQL inspection -> no plaintext payload
```

---

## M4 — Modern Tailwind UI

Deliver:

```text
responsive shell
sidebar
mobile navigation
dashboard
category filters
secret cards
masked fields
reveal/hide
copy
dark mode
toast/status UI
```

Acceptance:

desktop + mobile system tests.

---

## M5 — `.env` vault

Deliver:

```text
.env parser
structured environment editor
per-value reveal/copy
complete .env export
download stream
```

Acceptance:

complex `.env` fixtures round-trip correctly.

---

## M6 — Audit + version history

Deliver:

```text
audit events
history screen
restore UI
append-only model behavior
log canary tests
```

Acceptance:

audit trail contains actions but no secret values.

---

## M7 — Key rotation

Deliver:

```text
generate next KEK
dry-run rotation
batch rewrap
resume
verification
key status lifecycle
rotation report
```

Acceptance:

```text
all secrets decrypt after rotation
ciphertext bytes unchanged
wrapped DEK changed
old key not deleted automatically
```

---

## M8 — Backup / restore

Deliver:

```text
backup script
optional age encryption
checksum
restore script
verification script
BACKUP-RESTORE.md
```

Acceptance:

fresh DB restore + real decrypt PASS.

---

## M9 — Production hardening

Deliver:

```text
MFA
reauthentication
rate limiting
CSP
security headers
no-store sensitive responses
session controls
Brakeman/bundler-audit clean
```

Acceptance:

security checklist green.

---

## M10 — Production demo

Deliver:

```text
Docker production build
Kamal config
HTTPS
public demo mode
fake seeded secrets
README screenshots
deployment smoke tests
```

Acceptance:

public demo does not contain or accept real personal secrets.

---

## M11 — Personal deployment

Deliver:

```text
separate instance
signups disabled
MFA
persistent DB
separate KEK
offsite backup
restore drill
```

Acceptance:

full end-to-end recovery exercise PASS.

---

# 53. Exact first development sequence

Use this order; do not begin with UI polish.

```text
1. Bootstrap Rails/PostgreSQL/Tailwind.
2. Commit clean baseline.
3. Add authentication.
4. Add registration policy.
5. Create DB migrations for vault/key/audit tables.
6. Implement Crypto::AadBuilder.
7. Implement Crypto::Envelope.
8. Implement Crypto::PayloadSerializer.
9. Implement KeyProviders::Base/Registry.
10. Implement LocalFileKeyProvider.
11. Implement EnvelopeEncryptor.
12. Complete crypto tamper tests.
13. Implement key-generation CLI.
14. Implement Vault::CreateItem.
15. Implement Vault::RevealItem.
16. Prove PostgreSQL contains no plaintext.
17. Implement immutable update/versioning.
18. Implement restore-version.
19. Add audit logging.
20. Add Tailwind vault UI.
21. Add .env workflow.
22. Add key rotation.
23. Add backup/restore.
24. Perform fresh restore drill.
25. Add MFA/hardening.
26. Deploy public fake-data demo.
27. Deploy separate personal instance.
```

---

# 54. First proof-of-security checkpoint

Before adding many features, perform this manual proof:

Create a secret:

```text
title: Production Test
password: CANARY-VERY-SECRET-123
```

Then query PostgreSQL:

```sql
SELECT
  id,
  ciphertext,
  nonce,
  authentication_tag,
  wrapped_dek,
  key_provider,
  kek_id
FROM vault_item_versions;
```

Then search the database dump:

```bash
pg_dump ... > /tmp/vault.sql
grep -a "CANARY-VERY-SECRET-123" /tmp/vault.sql
```

Expected:

```text
no match
```

Then decrypt through the application and verify the canary is recovered.

This test should be documented with output/screenshots in the repository using **fake canary data only**.

---

# 55. Definition of Done for v1.0

v1.0 is done only when this entire chain passes:

```text
owner login
    |
create secret
    |
fresh per-version DEK
    |
AES-256-GCM
    |
wrap DEK using separate KEK
    |
PostgreSQL stores encrypted envelope
    |
server restart
    |
login
    |
decrypt exact original
    |
edit -> immutable new version
    |
restore old version
    |
tamper ciphertext -> hard failure
    |
rotate KEK
    |
ciphertext unchanged
    |
decrypt PASS
    |
backup PostgreSQL
    |
restore to fresh database
    |
load recovery KEK
    |
decrypt PASS
    |
production HTTPS + MFA
    |
PASS
```

Additional release gates:

```text
CI PASS
Brakeman PASS
bundler-audit PASS
no known plaintext secret in DB dump
no canary secret in logs
README complete
THREAT-MODEL.md complete
KEY-MANAGEMENT.md complete
BACKUP-RESTORE.md complete
public demo uses fake data only
```

---

# 56. v1.1 roadmap

Only after v1.0:

- AWS KMS provider;
- Google Cloud KMS provider;
- Azure Key Vault provider;
- encrypted import/export package;
- secure attachment encryption;
- secret expiration reminders;
- optional password generator;
- offline recovery manifest;
- periodic automated restore verification;
- passkeys/WebAuthn;
- blind-index research.

---

# 57. v2 research track

Potential separate architecture:

```text
user master passphrase
       |
Argon2id
       |
client/user KEK
       |
wrapped vault key
       |
encrypted secret data
```

This moves toward zero-knowledge behavior, but it changes recovery, browser cryptography, key derivation, sharing and threat assumptions substantially.

Do not mix this research into v1.

---

# 58. Architectural decision summary

Use these decisions unless a later threat-model review deliberately changes them:

```text
Framework              Rails 8.1.4
Production Ruby        Ruby 3.4.11
Compatibility Ruby     Ruby 4.0.x
Database               PostgreSQL 17
Frontend               Hotwire + Tailwind v4
Node/npm               Not required
User password           One-way hash (bcrypt baseline)
Secret encryption       AES-256-GCM
Data key                random 256-bit DEK per secret version
GCM nonce               random 96-bit
GCM tag                 128-bit
DEK protection          provider-wrapped by KEK
v1 key provider         LocalFileKeyProvider
KEK location            outside PostgreSQL and Git
Database payload        ciphertext only
Sensitive metadata      encrypted inside JSON payload
Versioning              immutable encrypted versions
Key rotation            rewrap DEKs, preserve ciphertext
Production deploy       Docker + Kamal
Public showcase         fake-data demo only
Personal vault          separate hardened deployment
Backup                  pg_dump + encrypted offsite artifact
Recovery acceptance     fresh restore + decrypt PASS
```

---

# 59. Official-reference notes used for this plan

At the time this plan was prepared:

- Rails 8.1.4 is the current stable Rails release.
- Rails 8 includes an official authentication generator.
- `tailwindcss-rails` v4 targets Tailwind CSS v4 and uses `tailwindcss-ruby`.
- Ruby 3.4 and Ruby 4.0 are both in normal maintenance.
- PostgreSQL 17 remains supported.
- Ruby OpenSSL documents GCM/AEAD support and explicitly warns against nonce reuse.
- OWASP recommends authenticated encryption modes such as GCM and separation of DEKs from KEKs where envelope encryption is used.
- Rails documents Kamal as a production deployment path.

Re-check exact dependency patch versions before each production release.

---

# 60. Immediate implementation target

The first coding checkpoint should produce these files and make their tests green:

```text
db/migrate/*create_vault_items*.rb
db/migrate/*create_vault_item_versions*.rb
db/migrate/*create_key_registries*.rb
db/migrate/*create_audit_events*.rb

app/services/crypto/errors.rb
app/services/crypto/aad_builder.rb
app/services/crypto/envelope.rb
app/services/crypto/payload_serializer.rb
app/services/crypto/envelope_encryptor.rb

app/services/key_providers/base.rb
app/services/key_providers/registry.rb
app/services/key_providers/local_file.rb

test/services/crypto/aad_builder_test.rb
test/services/crypto/envelope_encryptor_test.rb
test/services/key_providers/local_file_test.rb
```

Do **not** proceed to a polished secret-management UI until this cryptographic core and tamper-test suite is passing.

That sequencing is the central implementation rule for the project.
