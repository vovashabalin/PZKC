#!/usr/bin/env bash
# Usage: ./scripts/measure-build.sh NAME DOCKERFILE CONTEXT [TAG]
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 NAME DOCKERFILE CONTEXT [TAG]" >&2
  exit 2
fi

name="$1"
dockerfile="$2"
context="$3"
tag="${4:-lab2-${name}}"
results_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/results"
mkdir -p "$results_dir"

start_ns="$(date +%s%N)"
docker build --progress=plain -f "$dockerfile" -t "$tag" "$context" \
  2>&1 | tee "$results_dir/${name}.build.log"
end_ns="$(date +%s%N)"
size="$(docker image inspect "$tag" --format '{{.Size}}')"
elapsed_ms="$(( (end_ns - start_ns) / 1000000 ))"

printf '{\n  "name": "%s",\n  "tag": "%s",\n  "elapsed_ms": %s,\n  "image_size_bytes": %s\n}\n' \
  "$name" "$tag" "$elapsed_ms" "$size" | tee "$results_dir/${name}.json"
printf '%-24s %10sms %12s bytes\n' "$name" "$elapsed_ms" "$size"
