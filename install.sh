#!/bin/sh
#
# Installation script for dca
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/raginjason/dca/main/install.sh | sh
# 
# Or with custom install directory:
#   curl -fsSL https://raw.githubusercontent.com/raginjason/dca/main/install.sh | DCA_INSTALL_DIR=~/bin sh
#
# Environment variable overrides (for testing):
#   DCA_INSTALL_DIR  - Override the installation directory (default: ~/.local/bin)
#   DCA_VERSION      - Override the version to install, skips GitHub API lookup
#   DCA_TARBALL_URL  - Override the tarball URL (e.g. file:///path/to/fake.tar.gz)
#

set -o errexit
set -o nounset

# Determine installation directory
DCA_INSTALL_DIR="${DCA_INSTALL_DIR:-${HOME}/.local/bin}"

# Create install directory if it doesn't exist
mkdir -p "$DCA_INSTALL_DIR"

# Detect local mode: if bin/ exists next to this script, install from local files
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_COMMANDS_DIR="${HOME}/.claude/commands"
mkdir -p "$CLAUDE_COMMANDS_DIR"

if [ -d "${SCRIPT_DIR}/bin" ]; then
  echo "Installing dca from local source to ${DCA_INSTALL_DIR}"

  cp "${SCRIPT_DIR}/bin/dca" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-fork" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-code" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-cursor" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-devcontainer" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-config" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-session" "$DCA_INSTALL_DIR/"
  cp "${SCRIPT_DIR}/bin/dca-run" "$DCA_INSTALL_DIR/"

  chmod +x "$DCA_INSTALL_DIR/dca" "$DCA_INSTALL_DIR/dca-fork" "$DCA_INSTALL_DIR/dca-code" "$DCA_INSTALL_DIR/dca-cursor" "$DCA_INSTALL_DIR/dca-devcontainer" "$DCA_INSTALL_DIR/dca-config" "$DCA_INSTALL_DIR/dca-session" "$DCA_INSTALL_DIR/dca-run"

  cp "${SCRIPT_DIR}/.claude/commands/dca:plan.md" "$CLAUDE_COMMANDS_DIR/"
  cp "${SCRIPT_DIR}/.claude/commands/dca:implement.md" "$CLAUDE_COMMANDS_DIR/"
else
  # Determine which release to install
  REPO="raginjason/dca"
  if [ -n "${DCA_VERSION:-}" ]; then
    RELEASE="$DCA_VERSION"
  else
    RELEASE=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)
  fi

  if [ -z "$RELEASE" ]; then
    echo "Error: Could not determine latest release" >&2
    exit 1
  fi

  echo "Installing dca ${RELEASE} to ${DCA_INSTALL_DIR}"

  # Build or use override tarball URL
  if [ -n "${DCA_TARBALL_URL:-}" ]; then
    TARBALL_URL="$DCA_TARBALL_URL"
  else
    TARBALL_URL="https://github.com/${REPO}/releases/download/${RELEASE}/dca-${RELEASE}.tar.gz"
  fi
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT

  echo "Downloading from ${TARBALL_URL}..."
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$TEMP_DIR"

  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-fork" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-code" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-cursor" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-devcontainer" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-config" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-session" "$DCA_INSTALL_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/bin/dca-run" "$DCA_INSTALL_DIR/"

  chmod +x "$DCA_INSTALL_DIR/dca" "$DCA_INSTALL_DIR/dca-fork" "$DCA_INSTALL_DIR/dca-code" "$DCA_INSTALL_DIR/dca-cursor" "$DCA_INSTALL_DIR/dca-devcontainer" "$DCA_INSTALL_DIR/dca-config" "$DCA_INSTALL_DIR/dca-session" "$DCA_INSTALL_DIR/dca-run"

  cp "$TEMP_DIR/dca-${RELEASE}/.claude/commands/dca:plan.md" "$CLAUDE_COMMANDS_DIR/"
  cp "$TEMP_DIR/dca-${RELEASE}/.claude/commands/dca:implement.md" "$CLAUDE_COMMANDS_DIR/"
fi

echo "✓ Installation complete!"
echo ""
echo "To use dca, add to your PATH:"
echo "  export PATH=\"${DCA_INSTALL_DIR}:\$PATH\""
echo ""

# Check if install dir is in PATH
if echo "$PATH" | grep -q "$DCA_INSTALL_DIR"; then
  echo "✓ ${DCA_INSTALL_DIR} is already in your PATH"
else
  echo "⚠ ${DCA_INSTALL_DIR} is not in your PATH"
  echo "  Add this line to ~/.bashrc or ~/.zshrc:"
  echo "  export PATH=\"${DCA_INSTALL_DIR}:\$PATH\""
fi
