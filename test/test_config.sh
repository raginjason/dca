#!/bin/sh
#
# Test suite for bin/dca-config
#
# Usage:
#   sh test/test_config.sh
#
# All tests run in isolated temp directories. XDG_CONFIG_HOME is redirected
# to a temp dir so no writes go to the real user config.
#

set -o errexit
set -o nounset

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DCA_CONFIG="$REPO_ROOT/bin/dca-config"

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

assert_file_absent() {
    if [ ! -f "$1" ]; then
        pass "$2"
    else
        fail "$2 (expected no file at: $1)"
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

# Write a minimal settings.json with dev.containers.defaultFeatures.
make_settings() {
    dir="$1"
    cat > "$dir/settings.json" <<'EOF'
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/node:1": {}
  }
}
EOF
}

# Write a settings.json without the defaultFeatures key.
make_settings_no_features() {
    dir="$1"
    cat > "$dir/settings.json" <<'EOF'
{
  "editor.fontSize": 14
}
EOF
}

# ── Tests ─────────────────────────────────────────────────────────────────────

test_import_valid_file() {
    echo "Test: import — valid settings.json with defaultFeatures"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    make_settings "$TEMP"

    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import "$TEMP/settings.json" 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 on valid import"
    assert_file_exists "$TEMP/xdg/dca/config.json" "config.json is written"
    assert_output_contains "$output" "Imported 2 feature(s)" "reports feature count"
    assert_output_contains "$output" "$TEMP/xdg/dca/config.json" "reports destination path"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_missing_key() {
    echo "Test: import — settings.json without defaultFeatures key"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    make_settings_no_features "$TEMP"

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import "$TEMP/settings.json" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits non-zero when key is absent"
    assert_output_contains "$output" "not found in" "error mentions missing key"
    assert_file_absent "$TEMP/xdg/dca/config.json" "config.json is not written"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_file_not_found() {
    echo "Test: import — file does not exist"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import "$TEMP/nonexistent.json" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits non-zero when file is absent"
    assert_output_contains "$output" "not found" "error mentions missing file"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_missing_arg() {
    echo "Test: import — no argument given"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits non-zero with no arg"
    assert_output_contains "$output" "usage:" "shows usage"

    trap - EXIT
    rm -rf "$TEMP"
}

test_show_after_import() {
    echo "Test: show — after successful import prints JSON"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    make_settings "$TEMP"

    XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import "$TEMP/settings.json" >/dev/null
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" show 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "show exits 0 after import"
    assert_output_contains "$output" "ghcr.io" "show outputs feature JSON"

    trap - EXIT
    rm -rf "$TEMP"
}

test_show_no_config() {
    echo "Test: show — no config stored"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" show 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "show exits non-zero with no config"
    assert_output_contains "$output" "No features stored" "show reports no config"

    trap - EXIT
    rm -rf "$TEMP"
}

test_clear_after_import() {
    echo "Test: clear — removes config file"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    make_settings "$TEMP"

    XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import "$TEMP/settings.json" >/dev/null
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" clear 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "clear exits 0"
    assert_output_contains "$output" "Cleared" "clear confirms removal"
    assert_file_absent "$TEMP/xdg/dca/config.json" "config.json is removed"

    trap - EXIT
    rm -rf "$TEMP"
}

test_clear_nothing_stored() {
    echo "Test: clear — nothing stored exits 0"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" clear 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "clear exits 0 with no config"
    assert_output_contains "$output" "Nothing to clear" "clear reports nothing to do"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_vscode_present() {
    echo "Test: import-vscode — settings.json found at expected path"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    mkdir -p "$TEMP/xdg/Code/User"
    make_settings "$TEMP/xdg/Code/User"

    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import-vscode 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "import-vscode exits 0 when settings found"
    assert_file_exists "$TEMP/xdg/dca/config.json" "config.json is written via import-vscode"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_vscode_absent() {
    echo "Test: import-vscode — settings.json not present"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import-vscode 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "import-vscode exits non-zero when settings missing"
    assert_output_contains "$output" "not found" "error mentions missing file"

    trap - EXIT
    rm -rf "$TEMP"
}

test_import_cursor_present() {
    echo "Test: import-cursor — settings.json found at expected path"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT
    mkdir -p "$TEMP/xdg/Cursor/User"
    make_settings "$TEMP/xdg/Cursor/User"

    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" import-cursor 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "import-cursor exits 0 when settings found"
    assert_file_exists "$TEMP/xdg/dca/config.json" "config.json is written via import-cursor"

    trap - EXIT
    rm -rf "$TEMP"
}

test_no_args() {
    echo "Test: no args — exits non-zero and shows usage"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits non-zero with no args"
    assert_output_contains "$output" "usage:" "shows usage"

    trap - EXIT
    rm -rf "$TEMP"
}

test_help_flag() {
    echo "Test: --help — exits 0 and shows usage"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" --help 2>&1)"
    exit_code=$?

    assert_exit_code "$exit_code" 0 "exits 0 with --help"
    assert_output_contains "$output" "usage:" "shows usage"

    trap - EXIT
    rm -rf "$TEMP"
}

test_unknown_command() {
    echo "Test: unknown command — exits non-zero"
    TEMP="$(mktemp -d)"
    trap 'rm -rf "$TEMP"' EXIT

    set +e
    output="$(XDG_CONFIG_HOME="$TEMP/xdg" sh "$DCA_CONFIG" bogus 2>&1)"
    exit_code=$?
    set -e

    assert_exit_code "$exit_code" 1 "exits non-zero for unknown command"
    assert_output_contains "$output" "unknown command" "error mentions unknown command"

    trap - EXIT
    rm -rf "$TEMP"
}

# ── Run all ───────────────────────────────────────────────────────────────────

echo "Running dca-config tests..."
echo ""

test_import_valid_file
test_import_missing_key
test_import_file_not_found
test_import_missing_arg
test_show_after_import
test_show_no_config
test_clear_after_import
test_clear_nothing_stored
test_import_vscode_present
test_import_vscode_absent
test_import_cursor_present
test_no_args
test_help_flag
test_unknown_command

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
