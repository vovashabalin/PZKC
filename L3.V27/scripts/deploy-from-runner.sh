#!/usr/bin/env bash
# Called from the self-hosted runner. Required variables are injected by GitHub Secrets.
set -euo pipefail

: "${TARGET_HOST:?TARGET_HOST is required}"
: "${TARGET_USER:?TARGET_USER is required}"
: "${TARGET_SSH_KEY:?TARGET_SSH_KEY is required}"
: "${IMAGE_REF:?IMAGE_REF is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${APP_DB_PASSWORD:?APP_DB_PASSWORD is required}"

if [[ "$POSTGRES_PASSWORD" != "$APP_DB_PASSWORD" ]]; then
  echo "POSTGRES_PASSWORD and APP_DB_PASSWORD must be identical for the application database user." >&2
  exit 2
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_dir="$(mktemp -d)"
key_file="$(mktemp)"
trap 'rm -rf "$release_dir" "$key_file"' EXIT

printf '%s\n' "$TARGET_SSH_KEY" >"$key_file"
chmod 0600 "$key_file"

cat >"$release_dir/container.env" <<EOF
IMAGE_REF=$IMAGE_REF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
APP_DB_PASSWORD=$APP_DB_PASSWORD
EOF

cp "$root_dir/deploy/docker-compose.yml" "$release_dir/"
cp "$root_dir/deploy/config.toml" "$release_dir/"
cp "$root_dir/deploy/systemd/mywebapp-container.service" "$release_dir/"
cp "$root_dir/deploy/nginx/mywebapp.conf" "$release_dir/"

ssh_opts=(-i "$key_file" -o StrictHostKeyChecking=accept-new)
remote_stage="/tmp/mywebapp-release-${GITHUB_RUN_ID:-manual}"
ssh "${ssh_opts[@]}" "$TARGET_USER@$TARGET_HOST" "rm -rf '$remote_stage' && mkdir -p '$remote_stage'"
scp "${ssh_opts[@]}" "$release_dir"/* "$TARGET_USER@$TARGET_HOST:$remote_stage/"
ssh "${ssh_opts[@]}" "$TARGET_USER@$TARGET_HOST" \
  "sudo /usr/local/sbin/mywebapp-deploy '$remote_stage' && rm -rf '$remote_stage'"
