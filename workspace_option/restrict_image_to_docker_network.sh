#!/bin/bash
set -euo pipefail

NET_NAME="kasm_w/o_network"

if docker network inspect "$NET_NAME" >/dev/null 2>&1; then
  echo "Docker network '$NET_NAME' already exists."
  docker network ls --filter name="$NET_NAME"
  exit 0
fi

echo "Creating docker network: $NET_NAME"
docker network create --internal --driver=bridge "$NET_NAME"
echo "Created."
docker network ls --filter name="$NET_NAME"
