#!/usr/bin/env bash
# Post-deployment verification for laboratory work 1, variant 27.
set -euo pipefail

APP_HOST="127.0.0.1"
APP_PORT="3000"
DB_PORT="5432"

ok() { printf '[OK] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }

systemctl is-enabled --quiet mywebapp.socket || fail 'mywebapp.socket is not enabled'
systemctl is-active --quiet mywebapp.socket || fail 'mywebapp.socket is not active'
ok 'mywebapp.socket is enabled and active'

curl --fail --silent --show-error --max-time 20 "http://${APP_HOST}:${APP_PORT}/health/alive" | grep -qx 'OK' \
  || fail 'local /health/alive did not return OK'
curl --fail --silent --show-error --max-time 20 "http://${APP_HOST}:${APP_PORT}/health/ready" | grep -qx 'OK' \
  || fail 'local /health/ready did not return OK'
ok 'local health-check endpoints are ready'

systemctl is-active --quiet nginx || fail 'nginx is not active'
curl --fail --silent --show-error --max-time 20 -H 'Accept: text/html' http://127.0.0.1/ \
  | grep -q 'Notes Service' || fail 'nginx root endpoint did not return the HTML page'
curl --fail --silent --show-error --max-time 20 -H 'Accept: application/json' http://127.0.0.1/notes \
  | grep -q '^\[' || fail 'nginx /notes endpoint did not return a JSON list'
[[ "$(curl --silent --show-error --max-time 20 -o /dev/null -w '%{http_code}' http://127.0.0.1/health/alive)" == '404' ]] \
  || fail 'health endpoint is unexpectedly public through nginx'
ok 'nginx exposes only allowed endpoints'

ss -ltnH | grep -Eq "127\.0\.0\.1:${APP_PORT}[[:space:]]" \
  || fail "application is not listening on ${APP_HOST}:${APP_PORT}"
ss -ltnH | grep -Eq "127\.0\.0\.1:${DB_PORT}[[:space:]]" \
  || fail "PostgreSQL is not listening only on localhost:${DB_PORT}"
ok 'application and PostgreSQL listeners are local'

[[ "$(tr -d '[:space:]' </home/student/gradebook)" == '27' ]] \
  || fail 'gradebook file does not contain 27'
ok 'gradebook file contains the variant number'

printf '\nAll deployment checks passed.\n'
