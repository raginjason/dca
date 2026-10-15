#!/usr/bin/env bash
# Fail if a setup file references a host that is missing from hosts.txt, so the
# list a Claude cloud environment must allow cannot fall behind the code.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
files=("$here/install.sh" "$here/devcontainer-feature.json" "$here/../devcontainer.json")

listed="$(bash "$here/install.sh" --hosts | sort -u)"
# URLs, plus the registry host of the devcontainer base image reference.
used="$({
    grep -hoE 'https?://[A-Za-z0-9.-]+' "${files[@]}" | sed -E 's|https?://||'
    sed -nE 's|.*"image": *"([^/"]+)/.*|\1|p' "$here/../devcontainer.json"
} | sort -u)"

status=0
while read -r host; do
    if ! grep -qxF "$host" <<<"$listed"; then
        echo "check-hosts-listed: $host is used in setup files but missing from hosts.txt" >&2
        status=1
    fi
done <<<"$used"
exit "$status"
