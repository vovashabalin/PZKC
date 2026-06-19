#!/usr/bin/env bash
# Run on the separate runner VM; it does not deploy the application locally.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 2
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl git openssh-client jq
id runner >/dev/null 2>&1 || useradd --create-home --shell /bin/bash runner

cat <<'EOF'
Dependencies are installed.

Register the runner manually with a short-lived registration token obtained in:
Repository -> Settings -> Actions -> Runners -> New self-hosted runner.

Do not put the token in Git or in a shell history file. Register it as user
'runner' and use the label 'lab3-runner'. Stop or remove this VM after the lab.
EOF
