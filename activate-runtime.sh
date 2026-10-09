#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
default_runtime_root() {
  if [[ -d /kaggle/working && -w /kaggle/working ]]; then
    printf '%s\n' /kaggle/working/.ruby-envelope-vault-runtime
  elif [[ -d /content && -w /content ]]; then
    printf '%s\n' /content/.ruby-envelope-vault-runtime
  else
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/ruby-envelope-vault/runtime"
  fi
}
RUNTIME_ROOT="${RUNTIME_ROOT:-$(default_runtime_root)}"
if [[ -n "${ENV_FILE:-}" ]]; then :
elif [[ -f "$ROOT/.env.runtime" ]]; then ENV_FILE="$ROOT/.env.runtime"
else ENV_FILE="$ROOT/.env.kaggle"
fi
RUBY_VERSION="${RUBY_VERSION:-$(tr -d '[:space:]' < "$ROOT/.ruby-version")}"
export RUNTIME_ROOT ENV_FILE
export MISE_DATA_DIR="$RUNTIME_ROOT/mise/data"
export MISE_CONFIG_DIR="$RUNTIME_ROOT/mise/config"
export MISE_CACHE_DIR="$RUNTIME_ROOT/mise/cache"
export MISE_STATE_DIR="$RUNTIME_ROOT/mise/state"
export BUNDLE_PATH="$RUNTIME_ROOT/bundle"
export SE_CACHE_PATH="${SE_CACHE_PATH:-$RUNTIME_ROOT/selenium}"
export PATH="$RUNTIME_ROOT/bin:$RUNTIME_ROOT/mise/data/installs/ruby/$RUBY_VERSION/bin:$PATH"
chmod u+x "$ROOT/bootstrap.sh" "$ROOT/activate-runtime.sh" "$ROOT/activate-kaggle.sh" 2>/dev/null || true
find "$ROOT/bin" "$ROOT/script" -maxdepth 1 -type f -exec chmod u+x {} + 2>/dev/null || true
find "$RUNTIME_ROOT/mise/data/installs/ruby/$RUBY_VERSION/bin" -maxdepth 1 -type f -exec chmod u+x {} + 2>/dev/null || true
for dir in "$SE_CACHE_PATH" "$ROOT/tmp/selenium"; do
  [[ -d "$dir" ]] || continue
  find "$dir" -type f \( -name chromedriver -o -name chrome -o -name chrome-wrapper -o -name chrome_crashpad_handler -o -name chrome_sandbox \) -exec chmod u+x {} + 2>/dev/null || true
done
if [[ -d "$BUNDLE_PATH/ruby" ]]; then
  find "$BUNDLE_PATH/ruby" -type f \( -path '*/bin/*' -o -path '*/exe/*' \) -exec chmod u+x {} + 2>/dev/null || true
fi
[[ -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set +a; }
cd "$ROOT"
echo "Ruby: $(ruby -v)"
echo "Project: $PWD"
echo "Runtime: $RUNTIME_ROOT"
