#!/usr/bin/env bash
# Portable PostgreSQL, Redis and package setup functions sourced by bootstrap.sh.
# Expects runtime settings and shared shell helpers from the caller.

check_disk_space() {
  local free_kb free_mb
  free_kb="$(df -Pk "$RUNTIME_ROOT" | awk 'NR==2 {print $4}')"
  free_mb=$((free_kb / 1024))
  if (( free_mb < MIN_FREE_MB )); then
    warn "Only ${free_mb} MiB free under $RUNTIME_ROOT; Ruby/gems/PostgreSQL may need > ${MIN_FREE_MB} MiB."
  else
    ok "Free disk: ${free_mb} MiB"
  fi
}

install_postgresql_packages() {
  if ! apt-cache show "postgresql-${POSTGRES_MAJOR}" >/dev/null 2>&1; then
    local codename
    codename="$(. /etc/os-release 2>/dev/null; printf '%s' "${VERSION_CODENAME:-}")"
    if [[ -n "$codename" ]]; then
      log "PostgreSQL ${POSTGRES_MAJOR} is not in the distro repo; trying the official PGDG repository"
      local keyring="/usr/share/keyrings/postgresql-pgdg.gpg"
      local listfile="/etc/apt/sources.list.d/pgdg.list"
      if curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
          run_root gpg --dearmor --yes -o "$keyring"; then
        printf 'deb [signed-by=%s] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$keyring" "$codename" | \
          run_root tee "$listfile" >/dev/null
        run_root apt-get update -qq || true
      else
        warn "Could not install the PGDG signing key; falling back to distro PostgreSQL."
      fi
    fi
  fi

  if apt-cache show "postgresql-${POSTGRES_MAJOR}" >/dev/null 2>&1; then
    OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 3))
    run_root apt-get install -y --no-install-recommends \
      "postgresql-${POSTGRES_MAJOR}" "postgresql-client-${POSTGRES_MAJOR}" libpq-dev
  else
    warn "PostgreSQL ${POSTGRES_MAJOR} remains unavailable; installing the distro PostgreSQL version."
    OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 3))
    run_root apt-get install -y --no-install-recommends postgresql postgresql-client libpq-dev
  fi
}

install_apt_packages() {
  have apt-get || die "This bootstrap currently supports Debian/Ubuntu-derived images with apt-get."
  export DEBIAN_FRONTEND=noninteractive

  log "Installing OS packages (no systemd/Docker required)"
  run_root apt-get update -qq

  local libasound_package
  libasound_package="$(apt_first_available libasound2t64 libasound2)" || \
    die "Neither libasound2t64 nor libasound2 is available in this apt image"

  local packages=(
    ca-certificates curl git openssl python3 procps gnupg
    build-essential autoconf bison patch
    libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev
    libgdbm-dev libncurses-dev libdb-dev
    redis-server redis-tools
    fonts-liberation "$libasound_package" libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0
    libcairo2 libcups2 libgbm1 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0
    libudev1 libvulkan1 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6
    libxfixes3 libxkbcommon0 libxrandr2 xdg-utils
  )

  OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + ${#packages[@]}))
  run_root apt-get install -y --no-install-recommends "${packages[@]}"

  # Kaggle images often provide the pkg-config command via `pkgconf` and may
  # have R packages depending on that provider. Do not replace it with the
  # distro `pkg-config` package when the command already exists.
  if ! have pkg-config; then
    if apt-cache show pkgconf >/dev/null 2>&1; then
      OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 1))
      run_root apt-get install -y --no-install-recommends pkgconf
    else
      OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 1))
      run_root apt-get install -y --no-install-recommends pkg-config
    fi
  fi

  install_postgresql_packages

  if [[ "$INSTALL_AGE" == "1" ]]; then
    if apt-cache show age >/dev/null 2>&1; then
      OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 1))
      run_root apt-get install -y --no-install-recommends age
    else
      warn "age package is unavailable in this image; backup-db will still work in explicitly acknowledged plaintext mode."
    fi
  fi

  have pg_config || die "pg_config is missing after PostgreSQL installation"
  have redis-server || die "redis-server is missing after installation"
  ok "OS packages installed"
}

install_mise_and_ruby() {
  if [[ ! -x "$MISE_BIN" ]]; then
    log "Installing mise into $MISE_BIN"
    local mise_installer="$TMP_DIR/mise-install.sh"
    if ! curl -fsSL --connect-timeout 15 --retry 3 https://mise.run -o "$mise_installer"; then
      die "Cannot download mise. Enable Internet access for this host, then rerun bootstrap.sh."
    fi
    MISE_INSTALL_PATH="$MISE_BIN" sh "$mise_installer"
    rm -f "$mise_installer"
    chmod +x "$MISE_BIN"
  fi

  export PATH="$MISE_BIN_DIR:$PATH"
  log "Installing/activating Ruby $RUBY_VERSION through mise"
  "$MISE_BIN" install "ruby@$RUBY_VERSION"
  local ruby_home
  ruby_home="$($MISE_BIN where "ruby@$RUBY_VERSION")"
  export PATH="$ruby_home/bin:$PATH"

  [[ "$(ruby -e 'print RUBY_VERSION')" == "$RUBY_VERSION" ]] || \
    die "mise activated Ruby $(ruby -e 'print RUBY_VERSION'), expected $RUBY_VERSION"

  if ! have bundle || ! bundle -v 2>/dev/null | grep -q '2\.6\.9'; then
    gem install bundler -v 2.6.9 --no-document
  fi

  ok "$(ruby -v)"
  ok "$(bundle -v)"
}

ensure_service_packages() {
  local data_major="${POSTGRES_MAJOR}"
  if [[ -f "$PGDATA/PG_VERSION" ]]; then
    data_major="$(tr -d '[:space:]' < "$PGDATA/PG_VERSION")"
  fi

  if [[ ! -x "/usr/lib/postgresql/${data_major}/bin/pg_ctl" ]]; then
    have apt-get || die "PostgreSQL ${data_major} server binary is missing and apt-get is unavailable"
    export DEBIAN_FRONTEND=noninteractive
    run_root apt-get update -qq
    POSTGRES_MAJOR="$data_major" install_postgresql_packages
  fi

  if ! have redis-server; then
    have apt-get || die "redis-server is missing and apt-get is unavailable"
    export DEBIAN_FRONTEND=noninteractive
    run_root apt-get update -qq
    OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 2))
    run_root apt-get install -y --no-install-recommends redis-server redis-tools
  fi

  # Container images can lose Chrome runtime libraries while the Selenium
  # browser cache persists. Reinstall only when a known required library
  # package is missing.
  if ! dpkg-query -W libatk1.0-0 libatk-bridge2.0-0 libxcomposite1 libatspi2.0-0 >/dev/null 2>&1; then
    have apt-get || die "Chrome runtime libraries are missing and apt-get is unavailable"
    export DEBIAN_FRONTEND=noninteractive
    run_root apt-get update -qq
    local libasound_package
    libasound_package="$(apt_first_available libasound2t64 libasound2)" || \
      die "Neither libasound2t64 nor libasound2 is available in this apt image"
    OBS_INSTALLED_PACKAGES=$((OBS_INSTALLED_PACKAGES + 20))
    run_root apt-get install -y --no-install-recommends \
      fonts-liberation "$libasound_package" libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 \
      libcairo2 libcups2 libgbm1 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 \
      libudev1 libvulkan1 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 \
      libxfixes3 libxkbcommon0 libxrandr2 xdg-utils
  fi
}

postgres_bindir() {
  local data_major=""
  if [[ -f "$PGDATA/PG_VERSION" ]]; then
    data_major="$(tr -d '[:space:]' < "$PGDATA/PG_VERSION")"
  fi
  if [[ -n "$data_major" && -x "/usr/lib/postgresql/${data_major}/bin/pg_ctl" ]]; then
    printf '%s\n' "/usr/lib/postgresql/${data_major}/bin"
  elif [[ -x "/usr/lib/postgresql/${POSTGRES_MAJOR}/bin/pg_ctl" ]]; then
    printf '%s\n' "/usr/lib/postgresql/${POSTGRES_MAJOR}/bin"
  else
    pg_config --bindir
  fi
}

postgres_running() {
  [[ -f "$PGDATA/PG_VERSION" ]] || return 1
  run_pg "$(postgres_bindir)/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1
}

prepare_postgres_owner() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    id postgres >/dev/null 2>&1 || useradd --system --home-dir "$PG_RUNTIME" --shell /usr/sbin/nologin postgres
    chown -R postgres:postgres "$PG_RUNTIME"
    chmod 700 "$PGSOCKET"

    if [[ -f "$PGDATA/PG_VERSION" ]]; then
      chmod 700 "$PGDATA"
      install -d -o postgres -g postgres -m 700 \
        "$PGDATA/pg_commit_ts" "$PGDATA/pg_dynshmem" "$PGDATA/pg_notify" \
        "$PGDATA/pg_replslot" "$PGDATA/pg_serial" "$PGDATA/pg_snapshots" \
        "$PGDATA/pg_stat" "$PGDATA/pg_stat_tmp" "$PGDATA/pg_tblspc" \
        "$PGDATA/pg_twophase" "$PGDATA/pg_logical/snapshots" "$PGDATA/pg_logical/mappings"
    fi
  else
    chmod 700 "$PGSOCKET"
    [[ ! -d "$PGDATA" ]] || chmod 700 "$PGDATA"
  fi
}

start_postgres() {
  local bindir
  bindir="$(postgres_bindir)"
  prepare_postgres_owner

  if [[ -f "$PGDATA/PG_VERSION" ]]; then
    OBS_DATABASE_REUSED=yes
  fi

  if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
    log "Initializing private PostgreSQL cluster at $PGDATA"
    mkdir -p "$PGDATA"
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then chown postgres:postgres "$PGDATA"; fi
    chmod 700 "$PGDATA"
    run_pg "$bindir/initdb" -D "$PGDATA" --encoding=UTF8 --auth-local=trust --auth-host=scram-sha-256 >/dev/null
  fi

  if postgres_running; then
    OBS_POSTGRES_REUSED=yes
    if [[ -f "$PGDATA/postmaster.pid" ]]; then
      PG_PORT="$(sed -n '4p' "$PGDATA/postmaster.pid" | tr -d '[:space:]')"
      export PG_PORT
    fi
    ok "Managed PostgreSQL is already running on port ${PG_PORT:-unknown}"
    return
  fi

  local requested_port="${PG_PORT:-$PREFERRED_PG_PORT}"
  if port_in_use "$requested_port"; then
    requested_port="$(next_free_port "$requested_port")"
    warn "Preferred PostgreSQL port is busy; using $requested_port"
  fi
  PG_PORT="$requested_port"
  export PG_PORT

  cat >> "$PGDATA/postgresql.conf" <<EOF

# Rails 8 Envelope Encryption Vault portable bootstrap (last value wins on reruns)
listen_addresses = '127.0.0.1'
port = $PG_PORT
unix_socket_directories = '$PGSOCKET'
password_encryption = 'scram-sha-256'
max_connections = 50
shared_buffers = '128MB'
log_min_messages = warning
EOF

  log "Starting PostgreSQL on 127.0.0.1:$PG_PORT without systemd"
  run_pg "$bindir/pg_ctl" -D "$PGDATA" -l "$PGLOG" -w start >/dev/null
  "$bindir/pg_isready" -h 127.0.0.1 -p "$PG_PORT" >/dev/null
  ok "PostgreSQL $(run_pg "$bindir/postgres" --version | awk '{print $3}') on port $PG_PORT"
}

provision_postgres_databases() {
  local bindir user db testdb
  bindir="$(postgres_bindir)"
  user="${POSTGRES_APP_USER:-vault_user}"
  db="${POSTGRES_APP_DB:-ruby_envelope_vault_development}"
  testdb="${POSTGRES_TEST_DB:-ruby_envelope_vault_test}"
  POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(random_hex 24)}"

  [[ "$user" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Unsafe POSTGRES_APP_USER"
  [[ "$db" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Unsafe POSTGRES_APP_DB"
  [[ "$testdb" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Unsafe POSTGRES_TEST_DB"
  [[ "$POSTGRES_PASSWORD" =~ ^[A-Za-z0-9._-]+$ ]] || die "POSTGRES_PASSWORD must use only A-Z/a-z/0-9/._- for this bootstrap"
  export POSTGRES_PASSWORD POSTGRES_APP_USER="$user" POSTGRES_APP_DB="$db" POSTGRES_TEST_DB="$testdb"

  # Trust is local-socket-only for this private cluster. TCP uses SCRAM.
  if run_pg "$bindir/psql" -h "$PGSOCKET" -p "$PG_PORT" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${user}'" | grep -q 1; then
    run_pg "$bindir/psql" -h "$PGSOCKET" -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE ${user} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}'" >/dev/null
  else
    run_pg "$bindir/psql" -h "$PGSOCKET" -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 \
      -c "CREATE ROLE ${user} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}'" >/dev/null
  fi

  if ! run_pg "$bindir/psql" -h "$PGSOCKET" -p "$PG_PORT" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1; then
    run_pg "$bindir/createdb" -h "$PGSOCKET" -p "$PG_PORT" -O "$user" "$db"
  fi
  if ! run_pg "$bindir/psql" -h "$PGSOCKET" -p "$PG_PORT" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${testdb}'" | grep -q 1; then
    run_pg "$bindir/createdb" -h "$PGSOCKET" -p "$PG_PORT" -O "$user" "$testdb"
  fi

  DATABASE_URL="postgresql://${user}:${POSTGRES_PASSWORD}@127.0.0.1:${PG_PORT}/${db}"
  TEST_DATABASE_URL="postgresql://${user}:${POSTGRES_PASSWORD}@127.0.0.1:${PG_PORT}/${testdb}"
  export DATABASE_URL TEST_DATABASE_URL

  PGPASSWORD="$POSTGRES_PASSWORD" "$bindir/psql" "$DATABASE_URL" -Atqc 'SELECT 1' | grep -q '^1$'
  ok "PostgreSQL role/databases ready"
}

redis_running_managed() {
  [[ -f "$REDIS_PIDFILE" ]] || return 1
  local pid
  pid="$(cat "$REDIS_PIDFILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1
}

redis_managed_port() {
  [[ -f "$REDIS_CONF" ]] || return 1
  awk '$1 == "port" && $2 ~ /^[0-9]+$/ { print $2; exit }' "$REDIS_CONF"
}

start_redis() {
  REDIS_PASSWORD="${REDIS_PASSWORD:-$(random_hex 24)}"
  [[ "$REDIS_PASSWORD" =~ ^[A-Za-z0-9._-]+$ ]] || die "REDIS_PASSWORD must use only A-Z/a-z/0-9/._- for this bootstrap"
  export REDIS_PASSWORD

  if redis_running_managed; then
    OBS_REDIS_REUSED=yes
    # The private runtime config is the source of truth for a surviving managed
    # Redis process. A restored env file may still contain the old host port.
    REDIS_PORT="$(redis_managed_port || true)"
    [[ "$REDIS_PORT" =~ ^[0-9]+$ ]] || {
      warn "Managed Redis PID exists but its private config has no valid port; restarting it."
      kill "$(cat "$REDIS_PIDFILE")" >/dev/null 2>&1 || true
      for _ in {1..20}; do redis_running_managed || break; sleep 0.1; done
      rm -f "$REDIS_PIDFILE"
      REDIS_PORT=""
    }
    export REDIS_PORT
    if [[ -n "$REDIS_PORT" ]] && REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p "$REDIS_PORT" PING 2>/dev/null | grep -q PONG; then
      ok "Managed Redis is already running on port $REDIS_PORT"
      REDIS_URL="redis://:${REDIS_PASSWORD}@127.0.0.1:${REDIS_PORT}/0"
      export REDIS_URL
      return
    fi

    # A managed process exists but its environment file/password was lost or
    # changed. Stop only that PID (from our private runtime) before recreating it.
    warn "Managed Redis is running but current credentials do not match; restarting it."
    kill "$(cat "$REDIS_PIDFILE")" >/dev/null 2>&1 || true
    for _ in {1..20}; do redis_running_managed || break; sleep 0.1; done
    rm -f "$REDIS_PIDFILE"
  fi

  local requested_port="${REDIS_PORT:-$PREFERRED_REDIS_PORT}"
  if port_in_use "$requested_port"; then
    requested_port="$(next_free_port "$requested_port")"
    warn "Preferred Redis port is busy; using $requested_port"
  fi
  REDIS_PORT="$requested_port"
  export REDIS_PORT

  mkdir -p "$REDIS_RUNTIME/data"
  cat > "$REDIS_CONF" <<EOF
bind 127.0.0.1
protected-mode yes
port $REDIS_PORT
daemonize yes
supervised no
pidfile $REDIS_PIDFILE
logfile $REDIS_LOG
dir $REDIS_RUNTIME/data
dbfilename dump.rdb
appendonly no
save ""
requirepass $REDIS_PASSWORD
EOF
  chmod 600 "$REDIS_CONF"

  rm -f "$REDIS_PIDFILE"
  log "Starting Redis on 127.0.0.1:$REDIS_PORT without systemd"
  redis-server "$REDIS_CONF"
  for _ in {1..30}; do
    if REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p "$REDIS_PORT" PING 2>/dev/null | grep -q PONG; then break; fi
    sleep 0.2
  done
  REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p "$REDIS_PORT" PING | grep -q PONG
  REDIS_URL="redis://:${REDIS_PASSWORD}@127.0.0.1:${REDIS_PORT}/0"
  export REDIS_URL
  ok "Redis $(redis-server --version | sed -n 's/.*v=\([^ ]*\).*/\1/p') on port $REDIS_PORT"
}
