#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

if [[ ! -f .env ]]; then
  echo "Create L2.V27/.env from .env.example first." >&2
  exit 2
fi

docker compose up -d --build --wait

curl --fail --silent --show-error \
  -H 'Accept: text/html' \
  "http://127.0.0.1:${APP_HTTP_PORT:-80}/" >/dev/null

curl --fail --silent --show-error \
  -H 'Accept: application/json' \
  "http://127.0.0.1:${APP_HTTP_PORT:-80}/notes" >/dev/null

# health endpoints are intentionally unavailable through nginx.
status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "http://127.0.0.1:${APP_HTTP_PORT:-80}/health/alive")"
[[ "$status" == "404" ]]

docker compose exec -T app python - <<'PY'
from urllib.request import urlopen
for endpoint in ("/health/alive", "/health/ready"):
    response = urlopen(f"http://127.0.0.1:3000{endpoint}", timeout=3)
    assert response.status == 200
    assert response.read().decode() == "OK"
print("Internal health checks are OK")
PY

echo "Compose smoke test passed."
