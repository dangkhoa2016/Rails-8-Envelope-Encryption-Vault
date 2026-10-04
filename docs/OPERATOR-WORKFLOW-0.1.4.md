# Operator Workflow — 0.1.4-dev

## Purpose

This workflow gives an operator one safe status surface without promoting development code or printing secret values.

The development tree is not the live release. During normal 0.1.4 development:

- `/mnt/workspace/ruby-envelope-vault/current` remains stable `RELEASE-0.1.3`;
- stable Puma continues serving port 3000;
- `DEV-0.1.4` is edited and validated separately;
- release evidence for 0.1.3 is never reused as 0.1.4 acceptance evidence.

## Kaggle / notebook recovery

Recover services with the stable supported bootstrap and an external environment file:

```bash
cd /mnt/workspace/ruby-envelope-vault/current
ENV_FILE=/mnt/workspace/ruby-envelope-vault-secrets/source-env.kaggle \
START_SERVER=0 ./bootstrap.sh start
```

Then start stable Puma in its dedicated tmux window if it is not already running.

## Safe status from the development tree

```bash
cd /mnt/workspace/ruby-envelope-vault/DEV-0.1.4
ENV_FILE=/mnt/workspace/ruby-envelope-vault-secrets/source-env.kaggle \
./script/operator-status
```

Expected development identity while stable remains live:

```text
SOURCE_VERSION=0.1.4-dev
SOURCE_ROLE=development
CURRENT_TARGET=/mnt/workspace/ruby-envelope-vault/RELEASE-0.1.3
HEALTH_STATUS=200
POSTGRES_STATUS=ready
REDIS_STATUS=ready
OPERATOR_STATUS=PASS
```

The command intentionally prints no database URL, password, KEK contents, recovery identity, rclone credentials, MFA secret or vault plaintext.

## Durable Linux host distinction

A durable Linux/systemd host should continue to use the existing scheduler/service installation and live-host acceptance contracts. Kaggle recovery proves notebook/demo portability and restart behavior; it is not a recommendation to store irreplaceable production secrets on Kaggle.

## Promotion rule

Development status is never promotion evidence. Before a future 0.1.4 release candidate can become live:

1. complete the milestone scope;
2. run the full inherited 0.1.3 regression floor;
3. fork an immutable RC;
4. seal it;
5. stop at the explicit promotion gate;
6. exercise rollback;
7. promote explicitly;
8. verify post-promotion health/sealed source;
9. complete off-host artifact/evidence round trips.

Until then, `current` stays on stable 0.1.3.
