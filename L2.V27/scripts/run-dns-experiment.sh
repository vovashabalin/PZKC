#!/usr/bin/env bash
set -euo pipefail

network="dns-lab"
server="dns-server"

cleanup() {
  docker rm -f "$server" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "$network" >/dev/null
docker run -d --rm --name "$server" --network "$network" alpine:3.21 \
  sh -c "apk add --no-cache dnsmasq >/dev/null && \
  echo 'address=/myservice.internal.corp/10.0.0.50' > /etc/dnsmasq.conf && \
  exec dnsmasq -k --log-queries --log-facility=-" >/dev/null

sleep 2
dns_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$server")"

printf '\nUbuntu/glibc resolver:\n'
docker run --rm --network "$network" --dns="$dns_ip" --dns-search="corp" \
  ubuntu:24.04 getent hosts myservice.internal || true

printf '\nAlpine/musl resolver:\n'
docker run --rm --network "$network" --dns="$dns_ip" --dns-search="corp" \
  alpine:3.21 getent hosts myservice.internal || true

printf '\nDNS logs:\n'
docker logs "$server"
