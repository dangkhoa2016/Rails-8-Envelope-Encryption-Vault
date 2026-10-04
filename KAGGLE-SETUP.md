# Kaggle Notebook Setup — Ruby Envelope Vault v0.1.2-FIX4

This release includes a single Docker-free bootstrap entrypoint:

```bash
./bootstrap.sh
```

It is designed for the normal Kaggle Notebook terminal where Docker and systemd should not be assumed.

## Before running

Enable **Internet** for the Kaggle notebook. The first run needs network access for apt packages, mise/Ruby and Ruby gems.

Extract the project under `/kaggle/working`, then:

```bash
cd /kaggle/working/ruby-envelope-vault-v0.1.2
chmod +x bootstrap.sh
./bootstrap.sh
```

The default run installs everything, initializes the application, runs tests and finally starts Rails on port 3000.

If you want setup only:

```bash
START_SERVER=0 ./bootstrap.sh
```

If rerunning and you want a faster setup without the Rails suite:

```bash
RUN_TESTS=0 START_SERVER=0 ./bootstrap.sh
```

## What the one bootstrap file manages

The script installs or provisions:

- OS compiler/runtime packages;
- mise;
- Ruby 3.4.11;
- Bundler 2.6.9;
- application gems;
- PostgreSQL 17 when available from PGDG, otherwise the distro PostgreSQL;
- a private PostgreSQL data directory and application/test databases;
- Redis with a private localhost-only password-protected configuration;
- `age` when the package is available;
- a Vault KEK outside the project source tree;
- Rails database schema;
- Tailwind CSS build;
- crypto/security tests;
- the full Rails test suite plus a headless-Chrome system smoke test;
- Chrome-for-Testing shared libraries required by Selenium;
- optional owner creation;
- Rails web server.

No Docker, Docker Compose or systemd service startup is required.

## Runtime layout

By default Kaggle runtime data is placed under:

```text
/kaggle/working/.ruby-envelope-vault-runtime/
├── bin/
│   └── mise
├── mise/
├── bundle/
├── postgres/
│   ├── data/
│   ├── socket/
│   └── postgres.log
├── redis/
│   ├── data/
│   ├── redis.conf
│   ├── redis.pid
│   └── redis.log
├── keks/
│   └── kek-kaggle-01.key
└── tmp/
```

Application runtime variables are written to:

```text
.env.kaggle
```

with mode `0600`.

Do not commit this file.

## New terminal

After the first setup, activate the exact runtime with:

```bash
source ./activate-kaggle.sh
```

FIX4 also repairs executable-mode drift for project scripts, the persisted mise Ruby installation, Selenium/Chrome cache and Bundler `bin/`/`exe/` files. If a fresh Kaggle runtime has lost the PostgreSQL server package, `bootstrap.sh start/setup` reinstalls the major version required by persisted `PG_VERSION`; it also repairs PostgreSQL ownership/mode and standard empty runtime directories that notebook persistence may omit.

Then:

```bash
./bootstrap.sh status
script/project-doctor
```

## Create the first user

Interactive:

```bash
CREATE_OWNER=1 OWNER_EMAIL='you@example.com' START_SERVER=0 ./bootstrap.sh
```

For notebook automation, put the password in a mode-0600 file rather than in the notebook command history:

```bash
printf '%s' 'your-long-password' > /kaggle/working/owner-password
chmod 600 /kaggle/working/owner-password

CREATE_OWNER=1 \
OWNER_EMAIL='you@example.com' \
OWNER_PASSWORD_FILE=/kaggle/working/owner-password \
START_SERVER=0 \
./bootstrap.sh

rm -f /kaggle/working/owner-password
```

## Start / stop / status

```bash
./bootstrap.sh start
./bootstrap.sh status
./bootstrap.sh doctor
./bootstrap.sh stop
```

`start` runs Rails in the foreground. PostgreSQL and Redis are private background processes managed from the same runtime directory.

## Accessing the web server

Rails listens on:

```text
0.0.0.0:3000
```

Kaggle does not automatically publish notebook TCP ports to the Internet. If you need browser access from outside the notebook, use a tunnel you trust and keep authentication enabled.

## PostgreSQL behavior

The script does not rely on Ubuntu's packaged system cluster. It creates its own cluster under `/kaggle/working` and starts it with `pg_ctl`.

TCP authentication uses SCRAM-SHA-256. The bootstrap's private Unix socket uses local trust only so the local `postgres` OS account can administer its own cluster.

If port 5432 is already in use, the script selects the next free port and persists it in `.env.kaggle`.

## Redis behavior

Redis binds to `127.0.0.1`, uses protected mode and a generated password. If 6379 is busy, another free port is selected.

The current Rails vault does not depend on Redis for correctness; its existing Rails/Solid Cache path remains authoritative. Redis is provisioned because Kaggle experimentation and future cache/rate-limit adapters may use it, without making availability of Redis a requirement for decrypting secrets.

## Persistence warning

Treat Kaggle as a development/demo runtime. Notebook storage/session semantics can change or be reset.

For anything important, independently preserve both:

1. an encrypted PostgreSQL backup; and
2. every KEK still required to decrypt wrapped DEKs.

A database backup without the KEK is intentionally insufficient to recover vault plaintext.

## Useful overrides

```bash
RUNTIME_ROOT=/kaggle/working/my-vault-runtime ./bootstrap.sh
POSTGRES_MAJOR=17 ./bootstrap.sh
POSTGRES_PORT=55432 REDIS_PORT=56379 ./bootstrap.sh
PORT=3001 ./bootstrap.sh
RUN_TESTS=0 ./bootstrap.sh
START_SERVER=0 ./bootstrap.sh
INSTALL_AGE=0 ./bootstrap.sh
```

## Acceptance sequence

Before putting even test secrets in the vault:

```bash
source ./activate-kaggle.sh

./bootstrap.sh doctor
bin/rails test
bin/rails test:system
bin/rails vault:keys:verify
```

Then create a fake canary, prove it is not present in a database dump, and perform the documented backup/restore drill.
