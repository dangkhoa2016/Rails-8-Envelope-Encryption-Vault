# FIX25 Showcase Workflow

FIX25 provides a reproducible portfolio/demo workflow built entirely from synthetic data.

## Safety rules

- Demo fixtures contain fake values only.
- Never reuse production credentials in screenshots.
- The fixture still uses the real envelope-encryption path.
- Public screenshots must not include recovery keys, KEKs, rclone config, environment files, or operational secrets.

## Create a demo fixture

Create a password file outside the repository:

```bash
printf '%s' 'choose-a-demo-password-at-least-14-chars' > /tmp/revault-demo-password
chmod 600 /tmp/revault-demo-password
```

Then run:

```bash
DEMO_MODE=true \
DEMO_PASSWORD_FILE=/tmp/revault-demo-password \
DEMO_RESET=1 \
bin/rails demo:fixture
```

Default demo account:

```
showcase@example.test
```

The password is never hardcoded in the rake task.

## Synthetic fixture contents

The fixture creates encrypted examples for:

- Login
- API key
- Database
- Secure note
- Server / SSH
- Environment

The Acme Analytics example receives a second encrypted version so version-history UI has representative data.

## Capture screenshots

```bash
source ./activate-kaggle.sh
./script/capture-showcase
```

Default output:

```
tmp/showcase/screenshots/
```

Current capture set:

- 01-dashboard-desktop.png
- 02-vault-desktop.png
- 03-generator-desktop.png
- 04-audit-desktop.png
- 05-sessions-desktop.png
- 06-dashboard-mobile.png
- 07-vault-mobile.png

The capture harness runs in the Rails test environment and resets only its synthetic showcase user/data.
