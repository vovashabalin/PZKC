#!/usr/bin/env bash
# Create pinned requirements from the public starter project's dependency input.
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 PATH_TO_PYTHON_STARTER [--numpy]" >&2
  exit 2
fi

project_dir="$(cd "$1" && pwd)"
mode="${2:-}"
venv_dir="$(mktemp -d)"
trap 'rm -rf "$venv_dir"' EXIT

python3 -m venv "$venv_dir"
"$venv_dir/bin/python" -m pip install --upgrade pip

if [[ "$mode" == "--numpy" ]]; then
  "$venv_dir/bin/pip" install -r "$project_dir/requirements/backend.in" -r "$project_dir/requirements/numpy.in"
  "$venv_dir/bin/pip" freeze >"$project_dir/requirements/backend-numpy.lock"
  echo "Wrote requirements/backend-numpy.lock"
else
  "$venv_dir/bin/pip" install -r "$project_dir/requirements/backend.in"
  "$venv_dir/bin/pip" freeze >"$project_dir/requirements/backend.lock"
  echo "Wrote requirements/backend.lock"
fi
