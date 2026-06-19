#!/bin/sh
set -eu

: "${CONFIG_PATH:=/etc/mywebapp/config.toml}"
python migrate.py --config "$CONFIG_PATH"
exec gunicorn --bind 0.0.0.0:3000 --workers "${GUNICORN_WORKERS:-2}" \
  --access-logfile - --error-logfile - wsgi:app
