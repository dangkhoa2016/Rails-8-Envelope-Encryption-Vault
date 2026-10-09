#!/usr/bin/env bash

revault_production_env_path() {
  if [[ -n "${PRODUCTION_ENV_FILE:-}" ]]; then
    printf '%s\n' "$PRODUCTION_ENV_FILE"
    return 0
  fi

  if [[ -n "${OPS_ENV_FILE:-}" ]]; then
    printf '%s\n' "$OPS_ENV_FILE"
    return 0
  fi

  if [[ -r /etc/ruby-envelope-vault/ops.env ]]; then
    printf '%s\n' /etc/ruby-envelope-vault/ops.env
    return 0
  fi

  if [[ -n "${RUNTIME_ROOT:-}" ]]; then
    printf '%s/production.env\n' "$RUNTIME_ROOT"
    return 0
  fi

  if [[ -d /content && -w /content ]]; then
    printf '%s\n' /content/.ruby-envelope-vault-runtime/production.env
    return 0
  fi

  local kaggle_working
  kaggle_working="${KAGGLE_WORKING_DIR:-$(printf '/%s/%s' kaggle working)}"
  if [[ -d "$kaggle_working" && -w "$kaggle_working" ]]; then
    printf '%s/.ruby-envelope-vault-runtime/production.env\n' "$kaggle_working"
    return 0
  fi

  printf '%s\n' /etc/ruby-envelope-vault/ops.env
}

revault_validate_production_env_path() {
  local root="$1"
  local env_file="$2"
  local root_real env_real mode

  [[ "$env_file" == /* && "$env_file" != "/" ]] || {
    printf 'ERROR production env path must be absolute\n' >&2
    return 1
  }
  [[ -f "$env_file" && -r "$env_file" ]] || {
    printf 'ERROR production env file is not readable: %s\n' "$env_file" >&2
    return 1
  }

  root_real="$(cd "$root" && pwd -P)"
  env_real="$(cd "$(dirname "$env_file")" && pwd -P)/$(basename "$env_file")"
  case "$env_real" in
    "$root_real"|"$root_real"/*)
      printf 'ERROR production env file must live outside the application source tree\n' >&2
      return 1
      ;;
  esac

  mode="$(stat -c '%a' "$env_file" 2>/dev/null || stat -f '%Lp' "$env_file")"
  case "$mode" in
    600|400) ;;
    *)
      printf 'ERROR production env permissions must be 0600 or 0400\n' >&2
      return 1
      ;;
  esac
}

revault_load_production_env() {
  local root="$1"
  local env_file
  env_file="$(revault_production_env_path)"
  revault_validate_production_env_path "$root" "$env_file" || return 1
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
  export PRODUCTION_ENV_FILE="$env_file"
}
