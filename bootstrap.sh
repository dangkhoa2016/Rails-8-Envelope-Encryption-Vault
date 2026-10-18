#!/usr/bin/env bash
set -Eeuo pipefail

# Rails 8 Envelope Encryption Vault — portable notebook/container bootstrap
# ------------------------------------------------
# One-command, Docker-free setup for Kaggle, Colab, and similar
# Ubuntu/Debian containers without systemd.
#
# Default:
#   ./bootstrap.sh
#
# Useful overrides:
#   START_SERVER=0 ./bootstrap.sh
#   RUN_TESTS=0 ./bootstrap.sh
#   CREATE_OWNER=1 OWNER_EMAIL='me@example.com' ./bootstrap.sh
#   PORT=3000 ./bootstrap.sh
#
# Subcommands:
#   ./bootstrap.sh setup    # install + initialize + optionally start Rails (default)
#   ./bootstrap.sh start    # start PostgreSQL/Redis then Rails
#   ./bootstrap.sh status   # show service/runtime state
#   ./bootstrap.sh stop     # stop managed PostgreSQL/Redis
#   ./bootstrap.sh doctor   # run application doctor checks

COMMAND="${1:-setup}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Prefer host-local writable storage. Override RUNTIME_ROOT if desired.
if [[ -d /kaggle/working && -w /kaggle/working ]]; then
  DEFAULT_RUNTIME_ROOT="/kaggle/working/.ruby-envelope-vault-runtime"
elif [[ -d /content && -w /content ]]; then
  DEFAULT_RUNTIME_ROOT="/content/.ruby-envelope-vault-runtime"
else
  DEFAULT_RUNTIME_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/ruby-envelope-vault/runtime"
fi
RUNTIME_ROOT="${RUNTIME_ROOT:-$DEFAULT_RUNTIME_ROOT}"
if [[ -n "${ENV_FILE:-}" ]]; then
  :
elif [[ -f "$ROOT/.env.runtime" ]]; then
  ENV_FILE="$ROOT/.env.runtime"
else
  ENV_FILE="$ROOT/.env.kaggle"
fi
ACTIVATE_FILE="$ROOT/activate-runtime.sh"
RUBY_VERSION="${RUBY_VERSION:-$(tr -d '[:space:]' < "$ROOT/.ruby-version")}"
POSTGRES_MAJOR="${POSTGRES_MAJOR:-17}"
PREFERRED_PG_PORT="${POSTGRES_PORT:-5432}"
PREFERRED_REDIS_PORT="${REDIS_PORT:-6379}"
PORT="${PORT:-3000}"
START_SERVER="${START_SERVER:-1}"
RUN_TESTS="${RUN_TESTS:-1}"
CREATE_OWNER="${CREATE_OWNER:-0}"
INSTALL_AGE="${INSTALL_AGE:-1}"
MIN_FREE_MB="${MIN_FREE_MB:-3072}"

MISE_BIN_DIR="$RUNTIME_ROOT/bin"
MISE_BIN="$MISE_BIN_DIR/mise"
export MISE_DATA_DIR="$RUNTIME_ROOT/mise/data"
export MISE_CONFIG_DIR="$RUNTIME_ROOT/mise/config"
export MISE_CACHE_DIR="$RUNTIME_ROOT/mise/cache"
export MISE_STATE_DIR="$RUNTIME_ROOT/mise/state"

PG_RUNTIME="$RUNTIME_ROOT/postgres"
PGDATA="$PG_RUNTIME/data"
PGSOCKET="$PG_RUNTIME/socket"
PGLOG="$PG_RUNTIME/postgres.log"
REDIS_RUNTIME="$RUNTIME_ROOT/redis"
REDIS_CONF="$REDIS_RUNTIME/redis.conf"
REDIS_PIDFILE="$REDIS_RUNTIME/redis.pid"
REDIS_LOG="$REDIS_RUNTIME/redis.log"
KEK_DIR="$RUNTIME_ROOT/keks"
BUNDLE_DIR="$RUNTIME_ROOT/bundle"
TMP_DIR="$RUNTIME_ROOT/tmp"
SELENIUM_CACHE_DIR="$RUNTIME_ROOT/selenium"
DIAGNOSTICS_DIR="$RUNTIME_ROOT/diagnostics"
LATEST_BOOTSTRAP_SUMMARY="$DIAGNOSTICS_DIR/latest-bootstrap-summary.json"
if env | grep -q '^SE_CACHE_PATH='; then SELENIUM_CACHE_DIR="$SE_CACHE_PATH"; fi
export BUNDLE_PATH="$BUNDLE_DIR"
export SE_CACHE_PATH="$SELENIUM_CACHE_DIR"

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }

# FIX27 recovery/bootstrap observability. These counters report what the
# existing bootstrap path did; they must not change recovery decisions.
OBS_REUSED_TOOLS=0
OBS_REPAIRED_MODES=0
OBS_INSTALLED_PACKAGES=0
OBS_ASSETS_REBUILT=no
OBS_DATABASE_REUSED=no
OBS_POSTGRES_REUSED=no
OBS_REDIS_REUSED=no

count_reused_runtime_tools() {
  local tool
  OBS_REUSED_TOOLS=0
  if [[ -d "$RUNTIME_ROOT/bin" ]]; then
    for tool in "$RUNTIME_ROOT/bin/"*; do
      [[ -f "$tool" ]] || continue
      OBS_REUSED_TOOLS=$((OBS_REUSED_TOOLS + 1))
    done
  fi
}

emit_recovery_summary() {
  local release_version bootstrap_command generated_at
  release_version="$(tr -d '[:space:]' < "$ROOT/VERSION")"
  bootstrap_command="$COMMAND"
  generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  echo "RECOVERY_SUMMARY_BEGIN"
  echo "reused_tools=$OBS_REUSED_TOOLS"
  echo "repaired_modes=$OBS_REPAIRED_MODES"
  echo "installed_packages=$OBS_INSTALLED_PACKAGES"
  echo "assets_rebuilt=$OBS_ASSETS_REBUILT"
  echo "database_reused=$OBS_DATABASE_REUSED"
  echo "postgres_reused=$OBS_POSTGRES_REUSED"
  echo "redis_reused=$OBS_REDIS_REUSED"
  echo "RECOVERY_SUMMARY_END"

  mkdir -p "$DIAGNOSTICS_DIR"
  RELEASE_VERSION="$release_version" BOOTSTRAP_COMMAND="$bootstrap_command" GENERATED_AT="$generated_at" \
  OBS_REUSED_TOOLS="$OBS_REUSED_TOOLS" OBS_REPAIRED_MODES="$OBS_REPAIRED_MODES" \
  OBS_INSTALLED_PACKAGES="$OBS_INSTALLED_PACKAGES" OBS_ASSETS_REBUILT="$OBS_ASSETS_REBUILT" \
  OBS_DATABASE_REUSED="$OBS_DATABASE_REUSED" OBS_POSTGRES_REUSED="$OBS_POSTGRES_REUSED" \
  OBS_REDIS_REUSED="$OBS_REDIS_REUSED" python3 - "$LATEST_BOOTSTRAP_SUMMARY" <<'PYJSON'
import json, os, sys
from pathlib import Path
out = Path(sys.argv[1])
data = {
    "schema_version": 1,
    "release_version": os.environ["RELEASE_VERSION"],
    "command": os.environ["BOOTSTRAP_COMMAND"],
    "generated_at": os.environ["GENERATED_AT"],
    "reused_tools": int(os.environ["OBS_REUSED_TOOLS"]),
    "repaired_modes": int(os.environ["OBS_REPAIRED_MODES"]),
    "installed_packages": int(os.environ["OBS_INSTALLED_PACKAGES"]),
    "assets_rebuilt": os.environ["OBS_ASSETS_REBUILT"] == "yes",
    "database_reused": os.environ["OBS_DATABASE_REUSED"] == "yes",
    "postgres_reused": os.environ["OBS_POSTGRES_REUSED"] == "yes",
    "redis_reused": os.environ["OBS_REDIS_REUSED"] == "yes",
}
out.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n")
PYJSON
  chmod 644 "$LATEST_BOOTSTRAP_SUMMARY"
  echo "recovery_summary_json=$LATEST_BOOTSTRAP_SUMMARY"
}

ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

on_error() {
  local rc=$?
  printf '\n\033[1;31m[FAIL]\033[0m bootstrap failed at line %s (exit=%s)\n' "${BASH_LINENO[0]:-?}" "$rc" >&2
  printf 'Last command: %s\n' "${BASH_COMMAND:-unknown}" >&2
  printf 'PostgreSQL log: %s\nRedis log: %s\n' "$PGLOG" "$REDIS_LOG" >&2
  exit "$rc"
}
trap on_error ERR

have() { command -v "$1" >/dev/null 2>&1; }

apt_first_available() {
  local candidate
  for candidate in "$@"; do
    if apt-cache show "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

run_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "Root privileges are required to install apt packages on this host."
  fi
}

run_pg() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]] && id postgres >/dev/null 2>&1; then
    runuser -u postgres -- "$@"
  else
    "$@"
  fi
}

shell_quote() { printf '%q' "$1"; }

random_hex() {
  local bytes="${1:-32}"
  openssl rand -hex "$bytes"
}

port_in_use() {
  python3 - "$1" <<'PY'
import socket, sys
port = int(sys.argv[1])
s = socket.socket()
s.settimeout(0.2)
try:
    rc = s.connect_ex(("127.0.0.1", port))
finally:
    s.close()
sys.exit(0 if rc == 0 else 1)
PY
}

next_free_port() {
  local p="$1"
  while port_in_use "$p"; do p=$((p + 1)); done
  printf '%s' "$p"
}

load_existing_env() {
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    set -a
    source "$ENV_FILE"
    set +a
    log "Reusing secrets/settings from $ENV_FILE"
  fi
}

ensure_runtime_dirs() {
  mkdir -p "$RUNTIME_ROOT" "$MISE_BIN_DIR" "$MISE_DATA_DIR" "$MISE_CONFIG_DIR" \
    "$MISE_CACHE_DIR" "$MISE_STATE_DIR" "$PG_RUNTIME" "$PGSOCKET" \
    "$REDIS_RUNTIME" "$KEK_DIR" "$BUNDLE_DIR" "$TMP_DIR" "$SELENIUM_CACHE_DIR" "$DIAGNOSTICS_DIR"
  chmod 700 "$KEK_DIR"
  chmod 755 "$RUNTIME_ROOT" "$PG_RUNTIME" "$REDIS_RUNTIME" "$MISE_BIN_DIR"
}

repair_executable_modes() {
  chmod u+x "$ROOT/bootstrap.sh" "$ACTIVATE_FILE" 2>/dev/null || true
  if [[ -d "$RUNTIME_ROOT/bin" ]]; then
    local runtime_tool
    for runtime_tool in "$RUNTIME_ROOT/bin/"*; do
      [[ -f "$runtime_tool" ]] || continue
      if [[ ! -x "$runtime_tool" ]]; then
        log "Repairing executable mode for persistent runtime tool: $runtime_tool"
        if chmod u+x "$runtime_tool" 2>/dev/null; then
          OBS_REPAIRED_MODES=$((OBS_REPAIRED_MODES + 1))
        fi
      fi
    done
  fi
  find "$ROOT/bin" "$ROOT/script" -maxdepth 1 -type f -exec chmod u+x {} + 2>/dev/null || true

  local ruby_bin="$MISE_DATA_DIR/installs/ruby/$RUBY_VERSION/bin"
  if [[ -d "$ruby_bin" ]]; then
    find "$ruby_bin" -maxdepth 1 -type f -exec chmod u+x {} + 2>/dev/null || true
  fi

  local selenium_dir
  for selenium_dir in "$SELENIUM_CACHE_DIR" "$ROOT/tmp/selenium"; do
    [[ -d "$selenium_dir" ]] || continue
    find "$selenium_dir" -type f \
      \( -name chromedriver -o -name chrome -o -name chrome-wrapper -o -name chrome_crashpad_handler -o -name chrome_sandbox \) \
      -exec chmod u+x {} + 2>/dev/null || true
  done

  # Kaggle/device persistence may preserve bytes but drop executable bits from
  # gem-installed command/native binaries. Restore only conventional bin/exe
  # trees rather than making the entire bundle executable.
  if [[ -d "$BUNDLE_DIR/ruby" ]]; then
    find "$BUNDLE_DIR/ruby" -type f \
      \( -path '*/bin/*' -o -path '*/exe/*' \) \
      -exec chmod u+x {} + 2>/dev/null || true
  fi
}

write_env_file() {
  SECRET_KEY_BASE="${SECRET_KEY_BASE:-$(random_hex 64)}"
  VAULT_ACTIVE_KEK_ID="${VAULT_ACTIVE_KEK_ID:-kek-kaggle-01}"
  VAULT_KEK_DIR="$KEK_DIR"
  export SECRET_KEY_BASE VAULT_ACTIVE_KEK_ID VAULT_KEK_DIR

  umask 077
  {
    echo '# Generated by bootstrap.sh. DO NOT COMMIT.'
    printf 'export RAILS_ENV=%s\n' "$(shell_quote "${RAILS_ENV:-development}")"
    printf 'export DATABASE_URL=%s\n' "$(shell_quote "$DATABASE_URL")"
    printf 'export TEST_DATABASE_URL=%s\n' "$(shell_quote "$TEST_DATABASE_URL")"
    printf 'export POSTGRES_PASSWORD=%s\n' "$(shell_quote "$POSTGRES_PASSWORD")"
    printf 'export POSTGRES_APP_USER=%s\n' "$(shell_quote "$POSTGRES_APP_USER")"
    printf 'export POSTGRES_APP_DB=%s\n' "$(shell_quote "$POSTGRES_APP_DB")"
    printf 'export POSTGRES_TEST_DB=%s\n' "$(shell_quote "$POSTGRES_TEST_DB")"
    printf 'export PG_PORT=%s\n' "$(shell_quote "$PG_PORT")"
    printf 'export REDIS_URL=%s\n' "$(shell_quote "$REDIS_URL")"
    printf 'export REDIS_PASSWORD=%s\n' "$(shell_quote "$REDIS_PASSWORD")"
    printf 'export REDIS_PORT=%s\n' "$(shell_quote "$REDIS_PORT")"
    printf 'export SECRET_KEY_BASE=%s\n' "$(shell_quote "$SECRET_KEY_BASE")"
    printf 'export VAULT_KEY_PROVIDER=local_file\n'
    printf 'export VAULT_ACTIVE_KEK_ID=%s\n' "$(shell_quote "$VAULT_ACTIVE_KEK_ID")"
    printf 'export VAULT_KEK_DIR=%s\n' "$(shell_quote "$VAULT_KEK_DIR")"
    printf 'export ALLOW_SIGNUPS=%s\n' "$(shell_quote "${ALLOW_SIGNUPS:-true}")"
    printf 'export DEMO_MODE=%s\n' "$(shell_quote "${DEMO_MODE:-true}")"
    printf 'export APP_HOSTS=%s\n' "$(shell_quote "${APP_HOSTS:-localhost}")"
    printf 'export REQUIRE_MFA=%s\n' "$(shell_quote "${REQUIRE_MFA:-false}")"
    printf 'export REAUTH_ON_REVEAL=%s\n' "$(shell_quote "${REAUTH_ON_REVEAL:-true}")"
    printf 'export SESSION_IDLE_TIMEOUT_MINUTES=%s\n' "$(shell_quote "${SESSION_IDLE_TIMEOUT_MINUTES:-20}")"
    printf 'export SESSION_ABSOLUTE_TIMEOUT_HOURS=%s\n' "$(shell_quote "${SESSION_ABSOLUTE_TIMEOUT_HOURS:-12}")"
    printf 'export REAUTH_WINDOW_MINUTES=%s\n' "$(shell_quote "${REAUTH_WINDOW_MINUTES:-5}")"
    printf 'export PORT=%s\n' "$(shell_quote "$PORT")"
    printf 'export RAILS_LOG_TO_STDOUT=true\n'
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"

  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
  ok "Runtime environment saved to $ENV_FILE (0600)"
}

write_activation_helper() {
  # FIX21: keep the committed activation helper self-locating. Rewriting it
  # with absolute source paths would break after a notebook/container move.
  chmod +x "$ACTIVATE_FILE"
  grep -Fq 'BASH_SOURCE[0]' "$ACTIVATE_FILE" || die "activate-runtime.sh is not self-locating"
}


install_bundle() {
  log "Installing Ruby gems into $BUNDLE_DIR"
  BUNDLE_PATH="$BUNDLE_DIR" bundle install --jobs "$(nproc 2>/dev/null || echo 2)" --retry 3
  ok "Bundle installed"
}

build_web_assets() {
  OBS_ASSETS_REBUILT=yes
  log "Building Tailwind + Propshaft assets"
  rm -rf "$ROOT/public/assets" "$ROOT/public/assets-dev"
  bin/rails tailwindcss:build >/dev/null
  bin/rails assets:precompile >/dev/null
  local built_css
  built_css="$(find "$ROOT/public/assets" -maxdepth 1 -type f -name 'tailwind-*.css' -print -quit)"
  [[ -n "$built_css" ]] || die "Tailwind precompiled asset was not produced"
  grep -Fq '.lg\:grid{display:grid}' "$built_css" || die "Tailwind responsive utilities are missing from precompiled asset"
  ok "Web assets built with responsive utilities"
}

prepare_rails() {
  mkdir -p "$KEK_DIR" log tmp storage
  chmod 700 "$KEK_DIR"

  if [[ ! -f "$KEK_DIR/$VAULT_ACTIVE_KEK_ID.key" ]]; then
    log "Generating Vault KEK $VAULT_ACTIVE_KEK_ID"
    bin/rails vault:keys:generate ID="$VAULT_ACTIVE_KEK_ID" DIR="$KEK_DIR"
  fi
  chmod 600 "$KEK_DIR/$VAULT_ACTIVE_KEK_ID.key"

  log "Preparing PostgreSQL schema"
  bin/rails db:prepare

  build_web_assets

  bin/rails vault:keys:verify
  ok "Rails database + KEK prepared"
}

create_owner_if_requested() {
  [[ "$CREATE_OWNER" == "1" ]] || return 0

  local email="${OWNER_EMAIL:-}"
  if [[ -z "$email" && -t 0 ]]; then
    read -r -p "Owner email: " email
  fi
  [[ -n "$email" ]] || die "CREATE_OWNER=1 requires OWNER_EMAIL when stdin is non-interactive"

  local password_file="${OWNER_PASSWORD_FILE:-$TMP_DIR/owner-password}"
  if [[ -n "${OWNER_PASSWORD:-}" ]]; then
    umask 077
    printf '%s' "$OWNER_PASSWORD" > "$password_file"
  elif [[ -z "${OWNER_PASSWORD_FILE:-}" && -t 0 ]]; then
    local p1 p2
    read -r -s -p "Owner password (14+ chars): " p1; echo
    read -r -s -p "Confirm password: " p2; echo
    [[ "$p1" == "$p2" ]] || die "Passwords do not match"
    umask 077
    printf '%s' "$p1" > "$password_file"
    p1=''; p2=''
  fi

  [[ -f "$password_file" ]] || die "Provide OWNER_PASSWORD_FILE, OWNER_PASSWORD, or run interactively"
  EMAIL="$email" PASSWORD_FILE="$password_file" bin/rails vault:owner:create
  [[ "$password_file" == "$TMP_DIR/owner-password" ]] && rm -f "$password_file"
}

run_validation() {
  ./script/crypto-self-test
  ./script/security-self-test

  if [[ "$RUN_TESTS" == "1" ]]; then
    log "Checking Rails Zeitwerk autoloading"
    RAILS_ENV=test bin/rails zeitwerk:check
    log "Running Rails test suite"
    RAILS_ENV=test bin/rails db:prepare
    RAILS_ENV=test bin/rails test
    RAILS_ENV=test bin/rails test:system
  else
    warn "RUN_TESTS=0: Rails test suite skipped"
  fi

  ./script/project-doctor
}

start_rails() {
  log "Starting Rails on 0.0.0.0:$PORT"
  log "Kaggle does not expose notebook ports publicly by itself; use your preferred tunnel if needed."
  log "Press Ctrl+C to stop Rails. PostgreSQL/Redis remain managed by bootstrap.sh."
  exec bin/rails server -b 0.0.0.0 -p "$PORT"
}

stop_services() {
  if [[ -f "$PGDATA/PG_VERSION" ]] && have pg_config; then
    local bindir
    bindir="$(postgres_bindir)"
    if run_pg "$bindir/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
      log "Stopping PostgreSQL"
      run_pg "$bindir/pg_ctl" -D "$PGDATA" -m fast -w stop >/dev/null
    fi
  fi

  if redis_running_managed; then
    local rp="${REDIS_PORT:-$PREFERRED_REDIS_PORT}"
    local pw="${REDIS_PASSWORD:-}"
    if [[ -n "$pw" ]]; then
      REDISCLI_AUTH="$pw" redis-cli -h 127.0.0.1 -p "$rp" SHUTDOWN NOSAVE >/dev/null 2>&1 || true
    else
      kill "$(cat "$REDIS_PIDFILE")" >/dev/null 2>&1 || true
    fi
    rm -f "$REDIS_PIDFILE"
    log "Stopped Redis"
  fi
}

show_status() {
  echo "Project:       $ROOT"
  echo "Runtime:       $RUNTIME_ROOT"
  echo "Environment:   $ENV_FILE"
  echo "Ruby target:   $RUBY_VERSION"
  if have ruby; then echo "Ruby active:   $(ruby -v)"; else echo "Ruby active:   missing from PATH"; fi

  if [[ -f "$PGDATA/PG_VERSION" ]] && have pg_config && postgres_running; then
    echo "PostgreSQL:    running (port ${PG_PORT:-?}, data $PGDATA)"
  else
    echo "PostgreSQL:    stopped/not initialized"
  fi

  if redis_running_managed; then
    echo "Redis:         running (port ${REDIS_PORT:-?})"
  else
    echo "Redis:         stopped/not initialized"
  fi
  echo "Vault KEK:     $KEK_DIR/${VAULT_ACTIVE_KEK_ID:-kek-kaggle-01}.key"
  echo "Rails port:    $PORT"
}

setup_all() {
  ensure_runtime_dirs
  count_reused_runtime_tools
  repair_executable_modes
  check_disk_space
  install_apt_packages
  load_existing_env
  repair_executable_modes
  install_mise_and_ruby
  start_postgres
  provision_postgres_databases
  start_redis
  write_env_file
  write_activation_helper
  install_bundle
  prepare_rails
  create_owner_if_requested
  run_validation

  cat <<EOF

====================================================================
Rails 8 Envelope Encryption Vault portable bootstrap completed
====================================================================
Project:       $ROOT
Runtime:       $RUNTIME_ROOT
Ruby:          $(ruby -e 'print RUBY_VERSION')
PostgreSQL:    127.0.0.1:$PG_PORT
Redis:         127.0.0.1:$REDIS_PORT
Environment:   $ENV_FILE (0600)
KEK directory: $KEK_DIR
Rails:         http://127.0.0.1:$PORT

For a new terminal:
  source $(shell_quote "$ACTIVATE_FILE")

Service commands:
  ./bootstrap.sh status
  ./bootstrap.sh start
  ./bootstrap.sh stop
  ./bootstrap.sh doctor

Create owner later:
  CREATE_OWNER=1 OWNER_EMAIL='you@example.com' START_SERVER=0 ./bootstrap.sh

IMPORTANT: Notebook/container hosts should be treated as development/demo environments.
Do not put irreplaceable production credentials here without an independent,
tested backup of both PostgreSQL data and the Vault KEK.
====================================================================
EOF

  emit_recovery_summary

  if [[ "$START_SERVER" == "1" ]]; then
    start_rails
  fi
}

# Load service provisioning functions after shared runtime settings and helpers.
source "$ROOT/script/bootstrap-services-lib.sh"

case "$COMMAND" in
  setup)
    setup_all
    ;;
  start)
    ensure_runtime_dirs
    count_reused_runtime_tools
    load_existing_env
    repair_executable_modes
    ensure_service_packages
    repair_executable_modes
    install_mise_and_ruby
    start_postgres
    start_redis
    write_env_file
    write_activation_helper
    if ! BUNDLE_PATH="$BUNDLE_DIR" bundle check >/dev/null 2>&1; then
      install_bundle
    fi
    build_web_assets
    emit_recovery_summary
    if [[ "$START_SERVER" == "1" ]]; then
      start_rails
    else
      ok "START_SERVER=0: services are ready; Rails server not started"
    fi
    ;;
  stop)
    load_existing_env
    stop_services
    ;;
  status)
    load_existing_env
    show_status
    ;;
  doctor)
    load_existing_env
    install_mise_and_ruby
    ./script/project-doctor
    ;;
  *)
    die "Unknown command '$COMMAND'. Use: setup | start | stop | status | doctor"
    ;;
esac
