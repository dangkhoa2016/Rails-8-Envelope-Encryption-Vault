#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${1:-$(pwd)}"
RUN_TESTS="${RUN_TESTS:-1}"
cd "$PROJECT_DIR"

for f in config/initializers/rack_attack.rb test/test_helper.rb; do
  [[ -f "$f" ]] || { echo "[FAIL] missing $f in $PROJECT_DIR" >&2; exit 1; }
done

python3 - <<'PY'
from pathlib import Path

rack = Path("config/initializers/rack_attack.rb")
s = rack.read_text()
old = '''  def self.normalized_login_email(req)\n    body = req.body.read(4096).to_s\n    req.body.rewind\n    content_type = req.get_header("CONTENT_TYPE").to_s\n    email = if content_type.include?("application/json")\n      JSON.parse(body)["email_address"]\n    else\n      Rack::Utils.parse_nested_query(body)["email_address"]\n    end\n    email.to_s.strip.downcase.presence\n  rescue JSON::ParserError, Rack::QueryParser::InvalidParameterError, ArgumentError\n    nil\n  ensure\n    req.body.rewind rescue nil\n  end\n'''
new = '''  def self.normalized_login_email(req)\n    # Rack's parameter parser is the canonical source for form/query parameters\n    # and avoids hand-reading rack.input in throttling middleware. Keep a small\n    # JSON fallback for API-style requests.\n    email = req.params["email_address"]\n\n    if email.blank? && req.media_type == "application/json"\n      body = req.body.read(4096).to_s\n      req.body.rewind\n      email = JSON.parse(body)["email_address"]\n    end\n\n    email.to_s.strip.downcase.presence\n  rescue JSON::ParserError, Rack::QueryParser::InvalidParameterError, ArgumentError\n    nil\n  ensure\n    req.body.rewind rescue nil\n  end\n'''
if new not in s:
    if old not in s:
        raise SystemExit("[FAIL] unexpected normalized_login_email source; refusing blind patch")
    rack.with_suffix(rack.suffix + ".pre-fix2").write_text(s)
    rack.write_text(s.replace(old, new))
    print("[OK] patched Rack::Attack normalized login account key\n")
else:
    print("[SKIP] Rack::Attack FIX2 already present\n")

helper = Path("test/test_helper.rb")
s = helper.read_text()
base = '''class ActiveSupport::TestCase\n  parallelize(workers: 1)\nend\n'''
insert = '''class ActiveSupport::TestCase\n  parallelize(workers: 1)\nend\n\n# Rack::Attack uses the shared Rails cache. Request specs that intentionally\n# exhaust a throttle must not leak counters into unrelated integration tests.\n# This clears counters at the start of each integration test while preserving\n# normal accumulation across multiple requests inside the same test.\nclass ActionDispatch::IntegrationTest\n  setup do\n    Rack::Attack.cache.store.clear if defined?(Rack::Attack)\n    Current.reset if defined?(Current)\n  end\n\n  teardown do\n    Current.reset if defined?(Current)\n  end\nend\n'''
if insert not in s:
    if base not in s:
        raise SystemExit("[FAIL] unexpected test_helper source; refusing blind patch")
    helper.with_suffix(helper.suffix + ".pre-fix2").write_text(s)
    helper.write_text(s.replace(base, insert))
    print("[OK] isolated Rack::Attack/Current state between integration tests\n")
else:
    print("[SKIP] integration-test isolation FIX2 already present\n")
PY

ruby -c config/initializers/rack_attack.rb
ruby -c test/test_helper.rb

echo "[OK] FIX2 source patch applied"

if [[ "$RUN_TESTS" == "1" ]]; then
  if [[ -f ./activate-kaggle.sh ]]; then
    # shellcheck disable=SC1091
    source ./activate-kaggle.sh
  fi
  echo "[INFO] Running targeted request tests"
  RAILS_ENV=test bin/rails test \
    test/requests/rack_attack_test.rb \
    test/requests/vault_authorization_test.rb \
    test/requests/reauthentication_test.rb
  echo "[INFO] Running full Rails suite"
  RAILS_ENV=test bin/rails test
fi
