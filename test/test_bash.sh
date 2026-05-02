#!/bin/sh
#
# Test suite for bin/dca-bash
#
# Usage:
#   sh test/test_bash.sh
#
# Tests use a fake devcontainer binary that logs invocations to a temp file.
# XDG_CONFIG_HOME is redirected so no reads/writes touch the real user config.
#

set -o errexit
set -o nounset

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DCA_BASH="$REPO_ROOT/bin/dca-bash"

# ── Helpers ──────────────────────────────────────────────────────────────────

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

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

assert_file_contains() {
    if grep -qF -- "$2" "$1" 2>/dev/null; then
        pass "$3"
    else
        fail "$3 (expected '$2' in file '$1')"
    fi
}

# Create a fake devcontainer that logs all invocations to $FAKE_DEVCONTAINER_LOG.
make_fake_devcontainer() {
    dir="$1"
    mkdir -p "$dir"
    cat > "$dir/devcontainer" <<'FAKE'
#!/bin/sh
echo "$@" >> "$FAKE_DEVCONTAINER_LOG"
exit 0
FAKE
    chmod +x "$dir/devcontainer"
}

# Write a minimal config.json with stored features.
make_config() {
    xdg_dir="$1"
    mkdir -p "$xdg_dir/dca"
    cat > "$xdg_dir/dca/config.json" <<'EOF'
{
  "ghcr.io/devcontainers/features/git:1": {},
  "ghcr.io/devcontainers/features/node:1": {}
}
EOF
}

# ── Tests ─────────────────────────────────────────────────────────────────────

test_no_args() {
    echo "Test: no args — exits non-zero and shows usage"

    set +e
    output="$(sh "$DCA_BASH" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits 1 with no args"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_help_flag() {
    echo "Test: --help — exits 0 and shows usage"

    output="$(sh "$DCA_BASH" --help 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 with --help"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_h_flag() {
    echo "Test: -h — exits 0 and shows usage"

    output="$(sh "$DCA_BASH" -h 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 with -h"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_devcontainer_up_called() {
    echo "Test: devcontainer up is called before exec bash"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_BASH" "$TEMP/workspace" 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0"
    assert_file_contains "$LOG" "up" "devcontainer up was called"
    assert_file_contains "$LOG" "exec" "devcontainer exec was called"
    assert_file_contains "$LOG" "bash" "bash was requested via devcontainer exec"

    trap - EXIT
    rm -rf "$TEMP"
}

test_config_features_injected() {
    echo "Test: with config — stored features passed to devcontainer up"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    make_config "$TEMP/xdg"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_BASH" "$TEMP/workspace" 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0 with config present"
    assert_file_contains "$LOG" "ghcr.io/devcontainers/features/git" \
        "config git feature passed to devcontainer up"
    assert_file_contains "$LOG" "ghcr.io/devcontainers/features/node" \
        "config node feature passed to devcontainer up"

    trap - EXIT
    rm -rf "$TEMP"
}

test_passthrough_args() {
    echo "Test: extra args — forwarded to devcontainer up, not to exec"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_BASH" "$TEMP/workspace" \
        --remove-existing-container 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0 with passthrough arg"
    assert_file_contains "$LOG" "--remove-existing-container" \
        "passthrough arg forwarded to devcontainer up"

    trap - EXIT
    rm -rf "$TEMP"
}

test_missing_devcontainer() {
    echo "Test: devcontainer not on PATH — exits non-zero with error"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    mkdir -p "$TEMP/fakebin"
    if command -v jq >/dev/null 2>&1; then
        ln -s "$(command -v jq)" "$TEMP/fakebin/jq"
    fi
    _sh="$(command -v sh)"
    mkdir -p "$TEMP/workspace"

    set +e
    output="$(PATH="$TEMP/fakebin" "$_sh" "$DCA_BASH" "$TEMP/workspace" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits 1 when devcontainer missing"
    assert_output_contains "$output" "devcontainer" "error mentions devcontainer"

    trap - EXIT
    rm -rf "$TEMP"
}

# ── Run all ───────────────────────────────────────────────────────────────────

echo "Running dca-bash tests..."
echo ""

test_no_args
test_help_flag
test_h_flag
test_devcontainer_up_called
test_config_features_injected
test_passthrough_args
test_missing_devcontainer

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
