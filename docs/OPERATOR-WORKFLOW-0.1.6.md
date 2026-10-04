# Operator Workflow — DEV-0.1.6

## Purpose

Provide a secret-safe operator status surface while stable `RELEASE-0.1.5` remains live and immutable.

## Key-provider status

Run:

```bash
cd /content/DEV-0.1.6
ENV_FILE=/content/DEV-0.1.6/.env.kaggle ./script/key-provider-status
```

The command emits only:

- `KEY_PROVIDER_NAME`: allowlisted provider name (`local_file`, `aws_kms`, or `unknown`)
- `KEY_PROVIDER_STATUS`: `ready`, `unavailable`, `misconfigured`, or `error`
- `KEY_PROVIDER_CATEGORY`: coarse failure category only
- `KEY_PROVIDER_REMOTE`: `yes` or `no`

It intentionally does not print key IDs, KMS ARNs, AWS region, SDK exception messages, access keys, secret keys, session tokens, wrapped DEKs, ciphertext, or plaintext.

A non-ready provider exits non-zero.

## Combined operator status

```bash
cd /content/DEV-0.1.6
ENV_FILE=/content/DEV-0.1.6/.env.kaggle \
CURRENT_LINK=/content/current \
HEALTH_URL=http://127.0.0.1:3000/up \
./script/operator-status
```

The combined gate requires:
- resolvable `current`;
- HTTP health 200;
- PostgreSQL ready;
- Redis ready;
- key provider ready.

Provider failure therefore makes `OPERATOR_STATUS=FAIL` without exposing provider credentials or key material.
