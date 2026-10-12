#!/usr/bin/env bash
# Install the dev tools (adr-tools, shellcheck, shfmt, gh) at the versions pinned
# in versions.env. Runs as root, both at devcontainer image build time and from
# the Claude cloud SessionStart hook. Idempotent.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.env source-path=SCRIPTDIR
. "$here/versions.env"

case "$(uname -m)" in
    x86_64 | amd64) sc_arch=x86_64 sh_arch=amd64 ;;
    aarch64 | arm64) sc_arch=aarch64 sh_arch=arm64 ;;
    *)
        echo "dev-tools: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

install_adr_tools() {
    local prefix="/usr/local/lib/adr-tools"
    git -c advice.detachedHead=false clone --quiet --depth 1 \
        --branch "$ADR_TOOLS_VERSION" \
        https://github.com/npryce/adr-tools.git "$tmp/adr-tools"
    rm -rf "$prefix"
    mkdir -p "$prefix"
    cp -R "$tmp/adr-tools/src/." "$prefix/"
    # adr locates its sibling scripts relative to $0, so a symlink would break it.
    printf '#!/bin/sh\nexec "%s/adr" "$@"\n' "$prefix" >/usr/local/bin/adr
    chmod +x /usr/local/bin/adr
    echo "$ADR_TOOLS_VERSION" >"$prefix/.version"
}

install_shellcheck() {
    command -v xz >/dev/null || {
        apt-get update -qq && apt-get install -y -qq xz-utils
    }
    local base="https://github.com/koalaman/shellcheck/releases/download/v$SHELLCHECK_VERSION"
    curl -fsSL "$base/shellcheck-v$SHELLCHECK_VERSION.linux.$sc_arch.tar.xz" |
        tar -xJ -C "$tmp"
    install -m 0755 "$tmp/shellcheck-v$SHELLCHECK_VERSION/shellcheck" /usr/local/bin/shellcheck
}

install_shfmt() {
    curl -fsSL -o /usr/local/bin/shfmt \
        "https://github.com/mvdan/sh/releases/download/v$SHFMT_VERSION/shfmt_v${SHFMT_VERSION}_linux_$sh_arch"
    chmod 0755 /usr/local/bin/shfmt
}

install_gh() {
    curl -fsSL "https://github.com/cli/cli/releases/download/v$GH_VERSION/gh_${GH_VERSION}_linux_$sh_arch.tar.gz" |
        tar -xz -C "$tmp"
    install -m 0755 "$tmp/gh_${GH_VERSION}_linux_$sh_arch/bin/gh" /usr/local/bin/gh
}

# Installed versions, one function per tool; empty output means not installed.
adr_version() { cat /usr/local/lib/adr-tools/.version 2>/dev/null || true; }
shellcheck_version() { shellcheck --version 2>/dev/null | sed -n 's/^version: //p'; }
shfmt_version() { shfmt --version 2>/dev/null | sed 's/^v//'; }
gh_version() { gh --version 2>/dev/null | sed -n '1s/^gh version \([^ ]*\).*/\1/p'; }

[ "$(adr_version)" = "$ADR_TOOLS_VERSION" ] || install_adr_tools
[ "$(shellcheck_version)" = "$SHELLCHECK_VERSION" ] || install_shellcheck
[ "$(shfmt_version)" = "$SHFMT_VERSION" ] || install_shfmt
command -v gh >/dev/null || install_gh
