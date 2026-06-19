#!/usr/bin/env bash
# Run once on the separate target node as a sudo-capable administrator.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo: sudo ./target-bootstrap.sh" >&2
  exit 2
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg nginx openssh-server
install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker nginx

id deployer >/dev/null 2>&1 || useradd --create-home --shell /bin/bash deployer
install -d -o deployer -g deployer -m 0750 /opt/mywebapp
install -d -o root -g root -m 0750 /etc/mywebapp

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 0755 "$script_dir/mywebapp-deploy" /usr/local/sbin/mywebapp-deploy
install -m 0755 "$script_dir/mywebapp-verify" /usr/local/sbin/mywebapp-verify

cat >/etc/sudoers.d/deployer-mywebapp <<'EOF'
deployer ALL=(root) NOPASSWD: /usr/local/sbin/mywebapp-deploy, /usr/local/sbin/mywebapp-verify
EOF
chmod 0440 /etc/sudoers.d/deployer-mywebapp
visudo -cf /etc/sudoers.d/deployer-mywebapp

echo "Bootstrap finished. Add the self-hosted runner public SSH key to /home/deployer/.ssh/authorized_keys."
