#!/usr/bin/env bash
# Install adr-tools (https://github.com/npryce/adr-tools). Runs as root at
# image build time.
set -euo pipefail

version="${VERSION:-3.0.0}"
prefix="/usr/local/lib/adr-tools"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$version" \
    https://github.com/npryce/adr-tools.git "$tmp/adr-tools"

rm -rf "$prefix"
mkdir -p "$prefix"
cp -R "$tmp/adr-tools/src/." "$prefix/"

# adr locates its sibling scripts relative to $0, so a symlink would break it.
printf '#!/bin/sh\nexec "%s/adr" "$@"\n' "$prefix" >/usr/local/bin/adr
chmod +x /usr/local/bin/adr
