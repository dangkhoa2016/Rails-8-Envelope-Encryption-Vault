# Key Management — 1.0.0
Each immutable vault version receives a fresh random 32-byte DEK. AES-256-GCM encrypts the payload. The DEK is then wrapped by a separate KEK through the configured `KeyProvider`.
> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KEY-MANAGEMENT.vi.md)

The default provider is `local_file`. KEKs are raw 32-byte random files outside PostgreSQL and Git. Never reuse `RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, a user password, or a database password as a Vault KEK.

## Generate

```bash
VAULT_KEK_DIR=/secure/vault/keks bin/rails vault:keys:generate ID=kek-2026-01
```

The task uses exclusive file creation, mode 0600, refuses overwrite, and prints only key id/path/fingerprint — never key bytes.

## Verify

```bash
VAULT_ACTIVE_KEK_ID=kek-2026-01 \
VAULT_KEK_DIR=/secure/vault/keks \
bin/rails vault:keys:verify
```

## Rotation / DEK rewrap

Create the destination KEK first, then dry-run:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01 DRY_RUN=1
```

Perform rotation:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01
```

For each encrypted Vault version and MFA seed using the old key, the task:

1. unwraps the existing DEK with `FROM`;
2. wraps the same DEK with `TO` using a fresh wrapping nonce;
3. unwraps the new blob and constant-time verifies the DEK matches;
4. updates only `wrapped_dek` and `kek_id`;
5. leaves data ciphertext/nonce/tag unchanged.

The old registry entry becomes `decrypt_only`; the task never deletes the old KEK.

## Recovery rule

Keep a separate offline recovery copy of every KEK still referenced by any current backup. A PostgreSQL dump alone is intentionally insufficient to recover vault plaintext.

Do not retire/delete an old KEK until a backup taken after rotation has been restored into a fresh database and its canary secret decrypts successfully.

## recovery-custody verification

```bash
RECOVERY_KEK_DIR=/independent/recovery/keks script/kek-recovery-check
```

The check enumerates KEK IDs still referenced by encrypted Vault item versions and MFA records, then requires a separate recovery-directory copy with the same 32-byte fingerprint and restrictive 0400/0600 permissions.

A separate directory on the same Kaggle filesystem is useful only for testing the contract. Production acceptance still requires physically or administratively independent custody.
