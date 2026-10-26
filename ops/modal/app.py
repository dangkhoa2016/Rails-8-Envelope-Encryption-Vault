"""Two explicitly isolated Modal Apps using the SAME Rails source revision.

  REVAULT_MODAL_MODE=demo    modal deploy -e rails-8-envelope-encryption-vault ops/modal/app.py
  REVAULT_MODAL_MODE=private modal deploy -e ruby-envelope-private ops/modal/app.py

Secrets are provisioned separately per Modal environment. Never check them into Git.
"""
import os
from pathlib import Path

import modal

MODE = os.environ.get("REVAULT_MODAL_MODE", "").strip()
if MODE not in ("demo", "private"):
    raise ValueError("REVAULT_MODAL_MODE must explicitly be 'demo' or 'private'")

# Keep the private environment untouched. The dedicated public-demo app name
# is deliberately short to keep Modal's generated DNS label within 63 bytes.
if MODE == "demo":
    ENV_NAME = "rails-8-envelope-encryption-vault"
    APP_NAME = "vault-demo"
    SECRET_PREFIX = "rails-8-envelope-encryption-vault"
else:
    ENV_NAME = "ruby-envelope-private"
    APP_NAME = "ruby-envelope-vault-private"
    SECRET_PREFIX = "ruby-envelope-private"
# Modal copies this Python entrypoint to /root/app.py inside the worker,
# while the built Rails source resides at /rails. Resolve both contexts.
ROOT = Path("/rails") if Path("/rails/ops/modal/Dockerfile").is_file() else Path(__file__).resolve().parents[2]

app = modal.App(APP_NAME)
image = modal.Image.from_dockerfile(
    str(ROOT / "ops/modal/Dockerfile"),
    context_dir=str(ROOT),
    add_python="3.11",
).env({"REVAULT_MODAL_MODE": MODE})
crypto = modal.Secret.from_name(
    f"{SECRET_PREFIX}-crypto", environment_name=ENV_NAME,
    required_keys=["VAULT_KEK_B64", "VAULT_ACTIVE_KEK_ID"],
)
required_runtime_keys = ["SECRET_KEY_BASE", "APP_HOSTS"] + (
    ["DEMO_PASSWORD"] if MODE == "demo" else ["PRODUCTION_POSTGRES_URL"]
)
runtime = modal.Secret.from_name(
    f"{SECRET_PREFIX}-runtime", environment_name=ENV_NAME,
    required_keys=required_runtime_keys,
)


@app.function(
    image=image, secrets=[crypto, runtime],
    cpu=1.0, memory=3072,
    # Never scale PostgreSQL-in-a-container across multiple independent replicas.
    max_containers=1, min_containers=0, scaledown_window=240,
    timeout=3600,
)
@modal.web_server(3000, startup_timeout=360)
def web():
    import sys
    sys.path.insert(0, "/rails/ops/modal")
    from runtime import start_web

    start_web(MODE)
