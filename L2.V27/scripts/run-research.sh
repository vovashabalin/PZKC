#!/usr/bin/env bash
# Downloads only public starter projects into ignored work/ directory and runs build measurements.
set -euo pipefail

lab_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$lab_dir/research/work"
mkdir -p "$work"

if [[ ! -d "$work/python/.git" ]]; then
  git clone https://github.com/KPI-FICT-MTSD/lab-03-starter-project-python.git "$work/python"
fi
if [[ ! -d "$work/golang/.git" ]]; then
  git clone https://github.com/comsys-kpi-ua/deploy.lab-containers-starter-project-golang.git "$work/golang"
fi

"$lab_dir/scripts/lock-python-requirements.sh" "$work/python"

echo "Starter projects are available in: $work"
echo "Follow docs/experiments.md in this directory; it contains the exact commands for each experiment."
