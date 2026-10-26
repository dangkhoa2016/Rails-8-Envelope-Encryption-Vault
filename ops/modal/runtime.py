"""Modal runtime bootstrap. The private deployment never falls back to disposable storage."""
import base64
import glob
import os
import re
import secrets
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path

def select_database(mode, env):
    if mode not in ("demo", "private"):
        raise ValueError("INVALID_MODAL_MODE")
    url = env.get("PRODUCTION_POSTGRES_URL", "").strip()
    if mode == "demo":
        if url or env.get("DATABASE_URL", "").strip():
            raise ValueError("DEMO_MUST_NOT_USE_EXTERNAL_DATABASE")
        return None
    if not url:
        raise ValueError("PRIVATE_REQUIRES_PRODUCTION_POSTGRES_URL")
    parts = urllib.parse.urlsplit(url)
    if parts.scheme not in ("postgres", "postgresql") or not parts.hostname or not parts.path.strip("/"):
        raise ValueError("INVALID_POSTGRES_URL")
    if parts.hostname.lower() in ("localhost", "127.0.0.1", "::1"):
        raise ValueError("PRIVATE_REQUIRES_EXTERNAL_POSTGRES")
    query = urllib.parse.parse_qsl(parts.query, keep_blank_values=True)
    modes = [v for k, v in query if k == "sslmode"]
    if len(modes) > 1 or (modes and modes[0] not in ("require", "verify-ca", "verify-full")):
        raise ValueError("PRIVATE_REQUIRES_SSL_POSTGRES")
    if not modes:
        query.append(("sslmode", "require"))
    return urllib.parse.urlunsplit(parts._replace(query=urllib.parse.urlencode(query)))

def verify_config(mode, env):
    url = select_database(mode, env)
    if len(env.get("SECRET_KEY_BASE", "").encode()) < 64:
        raise ValueError("SECRET_KEY_BASE_MISSING_OR_SHORT")
    hosts = [h.strip() for h in env.get("APP_HOSTS", "").split(",") if h.strip()]
    if not hosts or any(any(ch.isspace() or ch in "<>/" for ch in h) for h in hosts):
        raise ValueError("INVALID_APP_HOSTS")
    if mode == "private" and any(h in ("localhost", "127.0.0.1", "::1") for h in hosts):
        raise ValueError("PRIVATE_HOSTS_CANNOT_INCLUDE_LOOPBACK")
    kid = env.get("VAULT_ACTIVE_KEK_ID", "")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", kid):
        raise ValueError("INVALID_KEK_ID")
    try:
        decoded = base64.b64decode(env.get("VAULT_KEK_B64", ""), validate=True)
    except Exception as exc:
        raise ValueError("INVALID_KEK_FORMAT") from exc
    if len(decoded) != 32:
        raise ValueError("INVALID_KEK_LENGTH")
    if mode == "demo" and len(env.get("DEMO_PASSWORD", "")) < 14:
        raise ValueError("INVALID_DEMO_PASSWORD")
    return url

def write_secret_file(name, data):
    path = Path(name)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(path.parent, 0o700)
    handle = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(handle, "wb") as out:
        out.write(data)
    return str(path)

def run_checked(command, *, stdin=None, env=None, cwd=None, error):
    result = subprocess.run(command, input=stdin, text=True, env=env, cwd=cwd,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=240)
    if result.returncode:
        raise RuntimeError(error)  # Never echo process stderr or secret connection strings.

def start_demo_postgres():
    """Disposable local-only PostgreSQL. No volume or snapshot survives a cold start."""
    binaries = sorted(glob.glob("/usr/lib/postgresql/*/bin"), reverse=True)
    if not binaries:
        raise RuntimeError("LOCAL_POSTGRES_NOT_INSTALLED")
    pg = binaries[0]
    data = "/tmp/revault-demo-postgres"
    Path(data).mkdir(mode=0o700)
    run_checked(["chown", "postgres:postgres", data], error="POSTGRES_DIR_FAILED")

    def pg_command(binary, *args, error):
        run_checked(["runuser", "-u", "postgres", "--", pg + "/" + binary, *args],
                    error=error)

    pg_command("initdb", "-D", data, "-U", "postgres",
               "--auth-local=trust", "--auth-host=scram-sha-256",
               "--no-instructions", error="POSTGRES_INIT_FAILED")
    pg_command("pg_ctl", "-D", data, "-l", "/tmp/revault-demo-pg.log",
               "-o", "-h 127.0.0.1 -p 5432", "-w", "start",
               error="POSTGRES_START_FAILED")
    # Generate a per-container role password, never print it.
    password = secrets.token_urlsafe(32)
    statement = "CREATE ROLE vault_demo LOGIN PASSWORD '" + password + "';\n"
    run_checked(["runuser", "-u", "postgres", "--", "psql", "-U", "postgres",
                 "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-f", "-"],
                stdin=statement, error="POSTGRES_ROLE_FAILED")
    run_checked(["runuser", "-u", "postgres", "--", "createdb",
                 "-O", "vault_demo", "ruby_envelope_demo"],
                error="POSTGRES_DATABASE_FAILED")
    return ("postgresql://vault_demo:" + urllib.parse.quote(password, safe="") +
            "@127.0.0.1:5432/ruby_envelope_demo")

def start_redis():
    with open("/tmp/revault-modal-redis.log", "w") as output:
        process = subprocess.Popen(
            ["redis-server", "--save", "", "--appendonly", "no",
             "--bind", "127.0.0.1", "--port", "6379"],
            stdout=output, stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL, start_new_session=True,
        )
    return process

def rails(args, env, error):
    run_checked(["bin/rails", *args], env=env, cwd="/rails", error=error)

def start_web(mode):
    os.umask(0o077)
    external = verify_config(mode, os.environ)
    kid = os.environ["VAULT_ACTIVE_KEK_ID"]
    key = base64.b64decode(os.environ["VAULT_KEK_B64"], validate=True)
    directory = "/dev/shm/revault-" + mode + "/keks"
    write_secret_file(directory + "/" + kid + ".key", key)
    del key

    url = external if external is not None else start_demo_postgres()
    env = os.environ.copy()
    env.update({
        "RAILS_ENV": "production", "RAILS_LOG_TO_STDOUT": "true",
        "RAILS_LOG_LEVEL": "warn", "DATABASE_URL": url,
        "VAULT_KEY_PROVIDER": "local_file",
        "VAULT_KEK_DIR": directory, "VAULT_ACTIVE_KEK_ID": kid,
        "DEMO_MODE": "true" if mode == "demo" else "false",
        "ALLOW_SIGNUPS": "false",
        "REQUIRE_MFA": "false" if mode == "demo" else "true",
        "REAUTH_ON_REVEAL": "true", "FORCE_SSL": "true",
        "ASSUME_SSL": "true", "PORT": "3000",
        "REDIS_URL": "redis://127.0.0.1:6379/0",
    })
    # Remove transport-only configuration and raw KEK after materializing files.
    env.pop("VAULT_KEK_B64", None)
    env.pop("PRODUCTION_POSTGRES_URL", None)

    redis = start_redis()
    if mode == "demo":
        password_path = write_secret_file(
            "/dev/shm/revault-demo/demo-password", os.environ["DEMO_PASSWORD"].encode()
        )
        env.update({"SHOW_PUBLIC_DEMO_CREDENTIALS": "true", "DEMO_PASSWORD_FILE": password_path,
                    "DEMO_EMAIL": "showcase@example.test", "DEMO_RESET": "false"})
        rails(["db:prepare"], env, "DEMO_DB_PREPARE_FAILED")
        rails(["demo:fixture"], env, "DEMO_FIXTURE_FAILED")
        print("MODAL_DATABASE=EPHEMERAL_POSTGRES")
        print("MODAL_CONTENT=SYNTHETIC_ONLY")
    else:
        for variable in ("DEMO_PASSWORD", "DEMO_EMAIL", "DEMO_RESET", "DEMO_PASSWORD_FILE", "SHOW_PUBLIC_DEMO_CREDENTIALS"):
            env.pop(variable, None)
        # The persistent database must already exist. Never seed a demo account.
        rails(["db:migrate"], env, "PRIVATE_DB_MIGRATION_FAILED")
        rails(["vault:keys:verify"], env, "PRIVATE_ACTIVE_KEK_VERIFY_FAILED")
        print("MODAL_DATABASE=PERSISTENT_EXTERNAL_POSTGRES")
        print("MODAL_CONTENT=PRIVATE_NO_DEMO_FIXTURES")

    with open("/tmp/revault-modal-puma.log", "w") as output:
        server = subprocess.Popen(
            ["bundle", "exec", "puma", "-C", "config/puma.rb"],
            cwd="/rails", env=env, stdout=output, stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL, start_new_session=True,
        )
    for _ in range(120):
        if server.poll() is not None or redis.poll() is not None:
            raise RuntimeError("MODAL_SERVER_EXITED_PREMATURELY")
        try:
            with urllib.request.urlopen("http://127.0.0.1:3000/ready", timeout=2) as response:
                if response.status == 200:
                    print("MODAL_RAILS_READY=PASS")
                    print("MODAL_DEPLOYMENT_MODE=" + mode)
                    return
        except Exception:
            time.sleep(2)
    raise RuntimeError("MODAL_RAILS_READINESS_TIMEOUT")
