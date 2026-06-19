#!/usr/bin/env bash
# One entry point for deploying the laboratory work on a clean Ubuntu Server 24.04 VM.
set -euo pipefail

APP_NAME="mywebapp"
APP_USER="app"
APP_DIR="/opt/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
CONFIG_PATH="${CONFIG_DIR}/config.toml"
DB_NAME="mywebapp"
DB_USER="mywebapp"
DB_PASSWORD="${DB_PASSWORD:-mywebapp_dev_27}"
DEFAULT_USER=""
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=deploy/variant.env
source "${ROOT_DIR}/deploy/variant.env"

usage() {
  cat <<USAGE
Usage: sudo ./deploy/install.sh --default-user USER

--default-user USER  User supplied by the VM image. The script blocks this user
                      after the required users and services are created.

Optional environment variable:
  DB_PASSWORD         PostgreSQL password for role ${DB_USER}.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --default-user)
      [[ $# -ge 2 ]] || { echo "--default-user needs a user name" >&2; exit 64; }
      DEFAULT_USER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script through sudo: sudo ./deploy/install.sh --default-user USER" >&2
  exit 1
fi

if [[ -z "$DEFAULT_USER" ]]; then
  echo "--default-user is required because the laboratory requires blocking the VM image user." >&2
  usage >&2
  exit 64
fi

if ! id "$DEFAULT_USER" &>/dev/null; then
  echo "Default VM user '${DEFAULT_USER}' does not exist. Installation was not started." >&2
  exit 64
fi

if [[ "$DEFAULT_USER" == "student" || "$DEFAULT_USER" == "teacher" || "$DEFAULT_USER" == "operator" || "$DEFAULT_USER" == "$APP_USER" ]]; then
  echo "The default VM user must not be one of the required laboratory users." >&2
  exit 64
fi

if [[ ! "$DB_PASSWORD" =~ ^[A-Za-z0-9._%+=,@:-]+$ ]]; then
  echo "DB_PASSWORD contains unsupported characters." >&2
  exit 64
fi

create_login_user() {
  local user_name="$1"
  if ! id "$user_name" &>/dev/null; then
    useradd --create-home --shell /bin/bash "$user_name"
  fi
  echo "${user_name}:12345678" | chpasswd
  chage --lastday 0 "$user_name"
}

ensure_postgresql_localhost() {
  local pg_config_file
  pg_config_file="$(runuser -u postgres -- psql -tAc 'SHOW config_file' | xargs)"
  if [[ -z "$pg_config_file" || ! -f "$pg_config_file" ]]; then
    echo "Could not determine postgresql.conf" >&2
    exit 1
  fi

  if grep -Eq "^[[:space:]#]*listen_addresses[[:space:]]*=" "$pg_config_file"; then
    sed -i -E "s|^[[:space:]#]*listen_addresses[[:space:]]*=.*|listen_addresses = '${DB_HOST}'|" "$pg_config_file"
  else
    printf "\nlisten_addresses = '%s'\n" "$DB_HOST" >> "$pg_config_file"
  fi
}

echo "[1/8] Installing required packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git nginx postgresql postgresql-contrib \
  python3 python3-venv python3-pip sudo

echo "[2/8] Creating required users..."
create_login_user student
create_login_user teacher
create_login_user operator
usermod -aG sudo student
usermod -aG sudo teacher

if ! id "$APP_USER" &>/dev/null; then
  useradd --system --home-dir "$APP_DIR" --create-home --shell /usr/sbin/nologin "$APP_USER"
fi

echo "[3/8] Restricting PostgreSQL to localhost and creating role/database..."
ensure_postgresql_localhost
systemctl restart postgresql

if ! runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';"
else
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}';"
fi

if ! runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
  runuser -u postgres -- createdb --owner="${DB_USER}" "${DB_NAME}"
fi

echo "[4/8] Copying application files and generating configuration..."
install -d -o "$APP_USER" -g "$APP_USER" -m 0755 "$APP_DIR"
rm -rf "${APP_DIR}/app"
cp -a "${ROOT_DIR}/app" "${APP_DIR}/app"
find "${APP_DIR}/app" -type d -name __pycache__ -prune -exec rm -rf {} +
find "${APP_DIR}/app" -type f -name '*.py[co]' -delete
chown -R "$APP_USER:$APP_USER" "${APP_DIR}/app"

python3 -m venv "${APP_DIR}/venv"
"${APP_DIR}/venv/bin/pip" install --upgrade pip
"${APP_DIR}/venv/bin/pip" install -r "${APP_DIR}/app/requirements.txt"
chown -R "$APP_USER:$APP_USER" "${APP_DIR}/venv"

install -d -o root -g "$APP_USER" -m 0750 "$CONFIG_DIR"
cat > "$CONFIG_PATH" <<CONFIG
[app]
host = "${APP_HOST}"
port = ${APP_PORT}

[database]
host = "${DB_HOST}"
port = ${DB_PORT}
name = "${DB_NAME}"
user = "${DB_USER}"
password = "${DB_PASSWORD}"
CONFIG
chown root:"$APP_USER" "$CONFIG_PATH"
chmod 0640 "$CONFIG_PATH"

echo "[5/8] Installing systemd units and operator restrictions..."
install -m 0644 "${ROOT_DIR}/deploy/systemd/mywebapp.service" /etc/systemd/system/mywebapp.service
install -m 0644 "${ROOT_DIR}/deploy/systemd/mywebapp.socket" /etc/systemd/system/mywebapp.socket
install -o root -g root -m 0755 "${ROOT_DIR}/deploy/mywebapp-control" /usr/local/sbin/mywebapp-control
install -o root -g root -m 0440 "${ROOT_DIR}/deploy/sudoers/operator-mywebapp" /etc/sudoers.d/operator-mywebapp
visudo -cf /etc/sudoers.d/operator-mywebapp
systemctl daemon-reload
systemctl enable --now mywebapp.socket

echo "[6/8] Triggering socket activation and checking the database migration..."
curl --fail --silent --show-error --max-time 20 http://${APP_HOST}:${APP_PORT}/health/alive >/dev/null
curl --fail --silent --show-error --max-time 20 http://${APP_HOST}:${APP_PORT}/health/ready >/dev/null

echo "[7/8] Configuring nginx reverse proxy..."
install -m 0644 "${ROOT_DIR}/deploy/nginx/mywebapp.conf" /etc/nginx/sites-available/mywebapp
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "[8/8] Writing gradebook file and blocking the image default user..."
printf '27\n' > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 0644 /home/student/gradebook

usermod --lock "$DEFAULT_USER"
usermod --shell /usr/sbin/nologin "$DEFAULT_USER"
echo "Blocked default VM user: ${DEFAULT_USER}"

echo
printf 'Deployment completed. Open http://<VM-IP>/ with Accept: text/html.\n'
printf 'Local health checks remain on http://%s:%s/health/{alive,ready}.\n' "$APP_HOST" "$APP_PORT"
printf 'Operator commands: sudo /usr/local/sbin/mywebapp-control {start|stop|restart|status}\n'
