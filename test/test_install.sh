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
# Creates the expected directory structure: dca-<version>/bin/{dca,dca-fork,dca-code}
make_fake_tarball() {
  version="$1"
  tarball_path="$2"
  staging_dir="$(mktemp -d)"
  mkdir -p "$staging_dir/dca-${version}/bin"
  printf '#!/bin/sh\necho "fake dca"\n'              > "$staging_dir/dca-${version}/bin/dca"
  printf '#!/bin/sh\necho "fake dca-fork"\n'         > "$staging_dir/dca-${version}/bin/dca-fork"
  printf '#!/bin/sh\necho "fake dca-code"\n'         > "$staging_dir/dca-${version}/bin/dca-code"
  printf '#!/bin/sh\necho "fake dca-devcontainer"\n' > "$staging_dir/dca-${version}/bin/dca-devcontainer"
  printf '#!/bin/sh\necho "fake dca-config"\n'       > "$staging_dir/dca-${version}/bin/dca-config"
  chmod +x "$staging_dir/dca-${version}/bin/dca" \
           "$staging_dir/dca-${version}/bin/dca-fork" \
           "$staging_dir/dca-${version}/bin/dca-code" \
           "$staging_dir/dca-${version}/bin/dca-devcontainer" \
           "$staging_dir/dca-${version}/bin/dca-config"
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

  DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    sh "$INSTALL_SH" >/dev/null 2>&1

  assert_file_exists "$INSTALL_DIR/dca"                "dca is installed"
  assert_file_exists "$INSTALL_DIR/dca-fork"            "dca-fork is installed"
  assert_file_exists "$INSTALL_DIR/dca-code"            "dca-code is installed"
  assert_file_exists "$INSTALL_DIR/dca-devcontainer"    "dca-devcontainer is installed"
  assert_file_exists "$INSTALL_DIR/dca-config"          "dca-config is installed"
  assert_executable  "$INSTALL_DIR/dca"                 "dca is executable"
  assert_executable  "$INSTALL_DIR/dca-fork"            "dca-fork is executable"
  assert_executable  "$INSTALL_DIR/dca-code"            "dca-code is executable"
  assert_executable  "$INSTALL_DIR/dca-devcontainer"    "dca-devcontainer is executable"
  assert_executable  "$INSTALL_DIR/dca-config"          "dca-config is executable"

  rm -rf "$TEST_DIR"
}

test_custom_install_dir_created() {
  echo "Test: custom DCA_INSTALL_DIR is created if missing"
  TEST_DIR="$(mktemp -d)"
  TARBALL="$TEST_DIR/dca-v1.0.0.tar.gz"
  INSTALL_DIR="$TEST_DIR/does/not/exist/yet"
  make_fake_tarball "v1.0.0" "$TARBALL"

  DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
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

  output=$(DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
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

  output=$(DCA_VERSION="v1.0.0" DCA_INSTALL_DIR="$INSTALL_DIR" DCA_TARBALL_URL="file://$TARBALL" \
    PATH="/usr/bin:/bin" sh "$INSTALL_SH" 2>&1)

  assert_output_contains "$output" "not in your PATH" "not-in-PATH warning shown"

  rm -rf "$TEST_DIR"
}

test_empty_release_fails() {
  echo "Test: empty DCA_VERSION causes error exit"
  TEST_DIR="$(mktemp -d)"
  INSTALL_DIR="$TEST_DIR/install"

  set +e
  DCA_VERSION="" DCA_INSTALL_DIR="$INSTALL_DIR" \
    sh "$INSTALL_SH" >/dev/null 2>&1
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
