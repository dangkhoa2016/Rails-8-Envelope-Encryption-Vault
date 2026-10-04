# Production Runtime Environment Contract — 0.1.7

## Goal

Production startup and diagnostics must not depend on a mutable DEV workspace,
a recovered release workspace, or a source-tree `.env.kaggle`.

Development keeps using the normal notebook `.env.kaggle` contract.

## Production env path resolution

The shared resolver uses this precedence:

1. `PRODUCTION_ENV_FILE` when explicitly set.
2. `OPS_ENV_FILE` for backward-compatible persistent-host operations.
3. `/etc/ruby-envelope-vault/ops.env` when readable.
4. `${RUNTIME_ROOT}/production.env`.
5. Notebook default:
   - `/content/.ruby-envelope-vault-runtime/production.env`, or
   - `/kaggle/working/.ruby-envelope-vault-runtime/production.env`.
6. `/etc/ruby-envelope-vault/ops.env` as the expected persistent-host path.

The production env file must:

- use an absolute path;
- exist and be readable;
- live outside the application source tree;
- have mode `0600` or `0400`.

The resolver prints only the path. It never prints env-file contents.

## Production startup

Use:

```bash
cd /opt/ruby-envelope-vault/current
PRODUCTION_ENV_FILE=/etc/ruby-envelope-vault/ops.env \
  script/start-production
```

Notebook acceptance example:

```bash
cd /content/DEV-0.1.7
PRODUCTION_ENV_FILE=/content/.ruby-envelope-vault-runtime/production.env \
PRODUCTION_PORT=3001 \
  script/start-production
```

`script/start-production` deliberately activates runtime/tool paths with
`ENV_FILE=/dev/null`, then loads only the external production env contract.

It does not fall back to `.env.kaggle` or recovery `source-env.kaggle`.

## Operator diagnostics

When `RAILS_ENV=production`, or when `PRODUCTION_ENV_FILE` /
`OPS_ENV_FILE` is explicitly set:

- `script/key-provider-status`
- `script/operator-status`

use the same production env resolver and permission/path checks.

Development behavior remains unchanged when those production selectors are not
present.

## Persistent systemd hosts

The existing systemd service already consumes:

`/etc/ruby-envelope-vault/ops.env`

which is a stable path outside the release tree. 0.1.7 keeps that contract
compatible rather than duplicating production secrets into another file.

## Notebook hosts

For Colab/Kaggle production-mode acceptance only, use:

`${RUNTIME_ROOT}/production.env`

This separates production-mode acceptance configuration from
`DEV-*/.env.kaggle` while keeping both outside source control.

## Security boundary

- No production env file is generated automatically from DEV env.
- No AWS credentials are copied by `script/start-production`.
- Production env values are never printed.
- Key IDs and plaintext remain subject to the existing redaction contracts.
- The AWS KMS startup/write guards from Milestones 1 and 2 remain authoritative.
