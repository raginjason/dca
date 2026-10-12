#!/usr/bin/env bash
# Claude cloud SessionStart hook: install the dev tools that the devcontainer
# provides via features (see doc/adr/0004). No-op outside Claude cloud.
set -euo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

root="$(cd "$(dirname "$0")/../.." && pwd)"
sudo=""
[ "$(id -u)" -eq 0 ] || sudo="sudo"

# Same installer and pinned versions (versions.env) as the devcontainer feature.
# It needs root and is a no-op when the tools are already at the pinned versions.
$sudo bash "$root/.devcontainer/dev-tools/install.sh"
