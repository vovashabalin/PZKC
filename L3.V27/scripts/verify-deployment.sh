#!/usr/bin/env bash
# Executes verification over SSH from the self-hosted runner.
set -euo pipefail

: "${TARGET_HOST:?TARGET_HOST is required}"
: "${TARGET_USER:?TARGET_USER is required}"
: "${TARGET_SSH_KEY:?TARGET_SSH_KEY is required}"

key_file="$(mktemp)"
trap 'rm -f "$key_file"' EXIT
printf '%s\n' "$TARGET_SSH_KEY" >"$key_file"
chmod 0600 "$key_file"

ssh -i "$key_file" -o StrictHostKeyChecking=accept-new "$TARGET_USER@$TARGET_HOST" 'sudo /usr/local/sbin/mywebapp-verify'
