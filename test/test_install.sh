#!/bin/sh
#
# Test suite for install.sh
#
# Usage:
#   sh test/test_install.sh
#
# All tests run in isolated temp directories. No writes to $HOME or system dirs.
#

set -o errexit
set -o nounset

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"

# ── Helpers ──────────────────────────────────────────────────────────────────

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_file_exists() {
  if [ -f "$1" ]; then
    pass "$2"
  else
    fail "$2 (expected file: $1)"
  fi
}

assert_executable() {
  if [ -x "$1" ]; then
    pass "$2"
  else
    fail "$2 (expected executable: $1)"
  fi
}

assert_output_contains() {
  if echo "$1" | grep -q "$2"; then
    pass "$3"
  else
    fail "$3 (expected '$2' in output)"
  fi
}

assert_exit_code() {
  if [ "$1" -eq "$2" ]; then
    pass "$3"
  else
    fail "$3 (expected exit code $2, got $1)"
  fi
}

# Build a fake release tarball at the given path for the given version.
make_fake_tarball() {
  version="$1"
  tarball_path="$2"
  staging_dir="$(mktemp -d)"
  mkdir -p "$staging_dir/dca-${version}/bin"
  mkdir -p "$staging_dir/dca-${version}/.claude/commands"
  printf '#!/bin/sh\necho "fake dca"\n'              > "$staging_dir/dca-${version}/bin/dca"
  printf '#!/bin/sh\necho "fake dca-lib"\n'          > "$staging_dir/dca-${version}/bin/dca-lib"
  printf '#!/bin/sh\necho "fake dca-fork"\n'         > "$staging_dir/dca-${version}/bin/dca-fork"
  printf '#!/bin/sh\necho "fake dca-code"\n'         > "$staging_dir/dca-${version}/bin/dca-code"
  printf '#!/bin/sh\necho "fake dca-cursor"\n'       > "$staging_dir/dca-${version}/bin/dca-cursor"
  printf '#!/bin/sh\necho "fake dca-devcontainer"\n' > "$staging_dir/dca-${version}/bin/dca-devcontainer"
  printf '#!/bin/sh\necho "fake dca-bash"\n'         > "$staging_dir/dca-${version}/bin/dca-bash"
  printf '#!/bin/sh\necho "fake dca-zsh"\n'          > "$staging_dir/dca-${version}/bin/dca-zsh"
  printf '#!/bin/sh\necho "fake dca-config"\n'       > "$staging_dir/dca-${version}/bin/dca-config"
  printf '#!/bin/sh\necho "fake dca-session"\n'      > "$staging_dir/dca-${version}/bin/dca-session"
  printf '#!/bin/sh\necho "fake dca-tmux"\n'         > "$staging_dir/dca-${version}/bin/dca-tmux"
  printf '#!/bin/sh\necho "fake dca-run"\n'          > "$staging_dir/dca-${version}/bin/dca-run"
  printf '# fake plan\n'                             > "$staging_dir/dca-${version}/.claude/commands/dca:plan.md"
  printf '# fake implement\n'                        > "$staging_dir/dca-${version}/.claude/commands/dca:implement.md"
  chmod +x "$staging_dir/dca-${version}/bin/dca" \
           "$staging_dir/dca-${version}/bin/dca-fork" \
           "$staging_dir/dca-${version}/bin/dca-code" \
           "$staging_dir/dca-${version}/bin/dca-cursor" \
           "$staging_dir/dca-${version}/bin/dca-devcontainer" \
           "$staging_dir/dca-${version}/bin/dca-bash" \
           "$staging_dir/dca-${version}/bin/dca-zsh" \
           "$staging_dir/dca-${version}/bin/dca-config" \
           "$staging_dir/dca-${version}/bin/dca-session" \
           "$staging_dir/dca-${version}/bin/dca-tmux" \
           "$staging_dir/dca-${version}/bin/dca-run"
  tar -czf "$tarball_path" -C "$staging_dir" "dca-${version}"
  rm -rf "$staging_dir"
}

# ── Tests ─────────────────────────────────────────────────────────────────────

test_happy_path_default_install_dir() {
  echo "Test: happy path — install to default dir"
  TEST_DIR="$(mktemp -d)"
  TARBALL="$TEST_DIR/dca-v1.0.0.tar.gz"
  INSTALL_DIR="$TEST_DIR/install"
  make_fake_tarball "v1.0.0" "$TARBALL"

  HOME="$TEST_DIR" DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    sh "$INSTALL_SH" >/dev/null 2>&1

  assert_file_exists "$INSTALL_DIR/dca"                "dca is installed"
  assert_file_exists "$INSTALL_DIR/dca-fork"           "dca-fork is installed"
  assert_file_exists "$INSTALL_DIR/dca-code"           "dca-code is installed"
  assert_file_exists "$INSTALL_DIR/dca-cursor"         "dca-cursor is installed"
  assert_file_exists "$INSTALL_DIR/dca-devcontainer"   "dca-devcontainer is installed"
  assert_file_exists "$INSTALL_DIR/dca-bash"           "dca-bash is installed"
  assert_file_exists "$INSTALL_DIR/dca-zsh"            "dca-zsh is installed"
  assert_file_exists "$INSTALL_DIR/dca-config"         "dca-config is installed"
  assert_file_exists "$INSTALL_DIR/dca-session"        "dca-session is installed"
  assert_file_exists "$INSTALL_DIR/dca-tmux"           "dca-tmux is installed"
  assert_file_exists "$INSTALL_DIR/dca-run"            "dca-run is installed"
  assert_executable  "$INSTALL_DIR/dca"                "dca is executable"
  assert_executable  "$INSTALL_DIR/dca-fork"           "dca-fork is executable"
  assert_executable  "$INSTALL_DIR/dca-code"           "dca-code is executable"
  assert_executable  "$INSTALL_DIR/dca-cursor"         "dca-cursor is executable"
  assert_executable  "$INSTALL_DIR/dca-devcontainer"   "dca-devcontainer is executable"
  assert_executable  "$INSTALL_DIR/dca-bash"           "dca-bash is executable"
  assert_executable  "$INSTALL_DIR/dca-zsh"            "dca-zsh is executable"
  assert_executable  "$INSTALL_DIR/dca-config"         "dca-config is executable"
  assert_executable  "$INSTALL_DIR/dca-session"        "dca-session is executable"
  assert_executable  "$INSTALL_DIR/dca-tmux"           "dca-tmux is executable"
  assert_executable  "$INSTALL_DIR/dca-run"            "dca-run is executable"

  rm -rf "$TEST_DIR"
}

test_custom_install_dir_created() {
  echo "Test: custom DCA_INSTALL_DIR is created if missing"
  TEST_DIR="$(mktemp -d)"
  TARBALL="$TEST_DIR/dca-v1.0.0.tar.gz"
  INSTALL_DIR="$TEST_DIR/does/not/exist/yet"
  make_fake_tarball "v1.0.0" "$TARBALL"

  HOME="$TEST_DIR" DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    sh "$INSTALL_SH" >/dev/null 2>&1

  assert_file_exists "$INSTALL_DIR/dca" "install dir was created and dca is present"

  rm -rf "$TEST_DIR"
}

test_path_already_set() {
  echo "Test: PATH already contains install dir"
  TEST_DIR="$(mktemp -d)"
  TARBALL="$TEST_DIR/dca-v1.0.0.tar.gz"
  INSTALL_DIR="$TEST_DIR/install"
  make_fake_tarball "v1.0.0" "$TARBALL"

  output=$(HOME="$TEST_DIR" DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    PATH="$INSTALL_DIR:$PATH" sh "$INSTALL_SH" 2>&1)

  assert_output_contains "$output" "already in your PATH" "already-in-PATH message shown"

  rm -rf "$TEST_DIR"
}

test_path_not_set() {
  echo "Test: PATH does not contain install dir"
  TEST_DIR="$(mktemp -d)"
  TARBALL="$TEST_DIR/dca-v1.0.0.tar.gz"
  INSTALL_DIR="$TEST_DIR/install"
  make_fake_tarball "v1.0.0" "$TARBALL"

  output=$(HOME="$TEST_DIR" DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    PATH="/usr/bin:/bin" sh "$INSTALL_SH" 2>&1)

  assert_output_contains "$output" "not in your PATH" "not-in-PATH warning shown"

  rm -rf "$TEST_DIR"
}

test_empty_release_fails() {
  echo "Test: empty DCA_VERSION causes error exit"
  TEST_DIR="$(mktemp -d)"
  INSTALL_DIR="$TEST_DIR/install"

  # Copy install.sh to a directory without a sibling bin/ so the remote code
  # path is exercised (local mode is skipped when bin/ doesn't exist next to it).
  cp "$INSTALL_SH" "$TEST_DIR/install.sh"

  # Fake curl that returns nothing — simulates a failed GitHub API call so
  # RELEASE stays empty and install.sh exits 1 with a deterministic error.
  mkdir -p "$TEST_DIR/fakebin"
  printf '#!/bin/sh\nexit 0\n' > "$TEST_DIR/fakebin/curl"
  chmod +x "$TEST_DIR/fakebin/curl"

  set +e
  HOME="$TEST_DIR" DCA_VERSION="" DCA_INSTALL_DIR="$INSTALL_DIR" \
    PATH="$TEST_DIR/fakebin:$PATH" sh "$TEST_DIR/install.sh" >/dev/null 2>&1
  exit_code=$?
  set -e

  assert_exit_code "$exit_code" 1 "exits with code 1 when version is empty"

  rm -rf "$TEST_DIR"
}

# ── Run all ───────────────────────────────────────────────────────────────────

echo "Running install.sh tests..."
echo ""

test_happy_path_default_install_dir
test_custom_install_dir_created
test_path_already_set
test_path_not_set
test_empty_release_fails

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
