#!/bin/sh
#
# Test suite for bin/dca-session
#
# Usage:
#   sh test/test_session.sh
#
# Tests use a fake devcontainer binary that logs invocations to a temp file.
# XDG_CONFIG_HOME is redirected so no reads/writes touch the real user config.
#

set -o errexit
set -o nounset

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DCA_SESSION="$REPO_ROOT/bin/dca-session"

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

# Create a fake devcontainer where the tmux availability check fails (simulates
# a pre-existing container that was built without tmux).
make_fake_devcontainer_no_tmux() {
    dir="$1"
    mkdir -p "$dir"
    cat > "$dir/devcontainer" <<'FAKE'
#!/bin/sh
echo "$@" >> "$FAKE_DEVCONTAINER_LOG"
case "$1" in
    exec)
        # Simulate tmux missing: fail the availability check but not the session exec
        if echo "$@" | grep -qF 'command -v tmux'; then
            exit 1
        fi
        ;;
esac
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
    output="$(sh "$DCA_SESSION" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits 1 with no args"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_help_flag() {
    echo "Test: --help — exits 0 and shows usage"

    output="$(sh "$DCA_SESSION" --help 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 with --help"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_h_flag() {
    echo "Test: -h — exits 0 and shows usage"

    output="$(sh "$DCA_SESSION" -h 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 with -h"
    assert_output_contains "$output" "usage:" "shows usage"
}

test_no_config_tmux_feature() {
    echo "Test: no config — tmux feature used as sole additional feature"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_SESSION" "$TEMP/workspace" 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0 with no config"
    assert_file_contains "$LOG" "ghcr.io/devcontainers-extra/features/tmux-apt-get" \
        "tmux feature included in --additional-features"

    trap - EXIT
    rm -rf "$TEMP"
}

test_config_merges_tmux() {
    echo "Test: with config — config features and tmux both present in additional-features"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    make_config "$TEMP/xdg"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_SESSION" "$TEMP/workspace" 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0 with config present"
    assert_file_contains "$LOG" "ghcr.io/devcontainers-extra/features/tmux-apt-get" \
        "tmux feature in merged additional-features"
    assert_file_contains "$LOG" "ghcr.io/devcontainers/features/git" \
        "config git feature in merged additional-features"
    assert_file_contains "$LOG" "ghcr.io/devcontainers/features/node" \
        "config node feature in merged additional-features"

    trap - EXIT
    rm -rf "$TEMP"
}

test_exec_tmux_session() {
    echo "Test: after devcontainer up — exec attaches to tmux session"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer "$TEMP/bin"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_SESSION" "$TEMP/workspace" 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0"
    assert_file_contains "$LOG" "tmux new-session -A -s main" \
        "tmux new-session called via devcontainer exec"

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
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_SESSION" "$TEMP/workspace" \
        --remove-existing-container 2>/dev/null
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 0 "exits 0 with passthrough arg"
    assert_file_contains "$LOG" "--remove-existing-container" \
        "passthrough arg forwarded to devcontainer up"

    trap - EXIT
    rm -rf "$TEMP"
}

test_tmux_not_in_container() {
    echo "Test: tmux missing in container — exits non-zero with rebuild hint"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    make_fake_devcontainer_no_tmux "$TEMP/bin"
    LOG="$TEMP/devcontainer.log"
    mkdir -p "$TEMP/workspace"

    set +e
    output="$(PATH="$TEMP/bin:$PATH" FAKE_DEVCONTAINER_LOG="$LOG" \
        XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_SESSION" "$TEMP/workspace" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits 1 when tmux missing in container"
    assert_output_contains "$output" "tmux not found" "error mentions tmux not found"
    assert_output_contains "$output" "remove-existing-container" "hint mentions --remove-existing-container"

    trap - EXIT
    rm -rf "$TEMP"
}

test_missing_devcontainer() {
    echo "Test: devcontainer not on PATH — exits non-zero with error"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    mkdir -p "$TEMP/fakebin"
    # Provide jq but not devcontainer so the devcontainer check triggers.
    # Use absolute sh path so the restricted PATH doesn't prevent sh from being found.
    if command -v jq >/dev/null 2>&1; then
        ln -s "$(command -v jq)" "$TEMP/fakebin/jq"
    fi
    _sh="$(command -v sh)"
    mkdir -p "$TEMP/workspace"

    set +e
    output="$(PATH="$TEMP/fakebin" "$_sh" "$DCA_SESSION" "$TEMP/workspace" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits 1 when devcontainer missing"
    assert_output_contains "$output" "devcontainer" "error mentions devcontainer"

    trap - EXIT
    rm -rf "$TEMP"
}

# ── Run all ───────────────────────────────────────────────────────────────────

echo "Running dca-session tests..."
echo ""

test_no_args
test_help_flag
test_h_flag
test_no_config_tmux_feature
test_config_merges_tmux
test_exec_tmux_session
test_passthrough_args
test_tmux_not_in_container
test_missing_devcontainer

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
