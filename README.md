# dca — Dev Container A\*

Fast setup for experimental work in isolated devcontainers.

> The `dc` stands for devcontainer. The `a` stands for AI, anarchy, or asylum — depending on the mood.

## Why

Quickly fork a repo and launch VS Code in a disposable devcontainer. No impact on your primary working tree. Perfect for agentic workflows that run in isolation.

## Quick Start

```sh
dca fork ~/original ~/experiment      # fork efficiently
dca code ~/experiment                 # open in VS Code devcontainer
```

```
/dca:plan        # end of VS Code planning session → writes STANDALONE_PLAN.md
```

```sh
dca run ~/experiment                  # run STANDALONE_PLAN.md unattended
dca session ~/experiment              # open tmux session inside container
```

## Commands

```
usage: dca <command> [<args>]

fork and setup
   fork           Fork repo efficiently using git references

launch and develop
   code           Open directory in VS Code devcontainer
   cursor         Open directory in Cursor devcontainer
   devcontainer   Start a devcontainer with stored defaultFeatures injected
   bash           Ensure a devcontainer is running and open a bash shell
   zsh            Ensure a devcontainer is running and open a zsh shell
   tmux           Ensure a devcontainer is running and attach to a tmux session
   session        Start a devcontainer with tmux and attach to a session
   run            Run STANDALONE_PLAN.md unattended with Claude Code

configure
   config         Manage stored devcontainer default features
```

### `dca fork <ref-repo> <target>`

Efficiently fork a repository locally using git references. The new fork shares git objects with the reference repo, then dissociates. Result: fast, isolated copy with no duplication.

```sh
dca fork ~/projects/myrepo ~/experiments/myrepo-feature
```

### `dca code <directory>`

Launch VS Code with the directory opened in a devcontainer context.

```sh
dca code ~/experiments/myrepo-feature
# or from inside the directory:
dca code .
```

### `dca cursor <directory>`

Launch Cursor with the directory opened in a devcontainer context. Behaves identically to `dca code` but opens Cursor instead of VS Code.

```sh
dca cursor ~/experiments/myrepo-feature
dca cursor .
```

### `dca bash <directory> [<devcontainer-args>...]`

Ensure a devcontainer is running for the given directory, then open a bash shell inside it. Stored features from `dca config` are injected.

```sh
dca bash .
dca bash ~/experiments/myrepo-feature
dca bash . --remove-existing-container
```

### `dca zsh <directory> [<devcontainer-args>...]`

Ensure a devcontainer is running for the given directory, then open a zsh shell inside it. Stored features from `dca config` are injected.

```sh
dca zsh .
dca zsh ~/experiments/myrepo-feature
dca zsh . --remove-existing-container
```

### `dca tmux <directory> [<devcontainer-args>...]`

Ensure a devcontainer is running for the given directory, then attach to a tmux session inside it. Unlike `dca session`, tmux is not automatically injected — the container must already have tmux installed.

```sh
dca tmux .
dca tmux ~/experiments/myrepo-feature
dca tmux . --remove-existing-container
```

### `dca session <directory>`

Start a devcontainer with [tmux](https://github.com/tmux/tmux) always installed, then attach to a persistent tmux session inside it. Stored features from `dca config` are injected alongside tmux. The tmux feature (`ghcr.io/devcontainers-extra/features/tmux-apt-get:1`) is always added and is never stored in config.

```sh
dca session .
dca session ~/experiments/myrepo-feature
# rebuild the container first, then attach
dca session . --remove-existing-container
```

After `devcontainer up` completes, this runs:

```sh
devcontainer exec --workspace-folder <dir> tmux new-session -A -s main
```

The `-A` flag attaches to an existing `main` session if one exists, creating it otherwise — so re-running `dca session` in the same container just reconnects.

> **Tip:** Add `ghcr.io/devcontainers-extra/features/tmux-apt-get:1` to `dev.containers.defaultFeatures` in your VS Code or Cursor settings, then run `dca config import-vscode` (or `import-cursor`). This ensures tmux is present in every devcontainer you create — including ones opened directly by VS Code — so `dca session` always works on the first try without needing `--remove-existing-container`.

### `dca run <directory>`

Run `STANDALONE_PLAN.md` unattended using Claude Code. Requires a `STANDALONE_PLAN.md` at the workspace root — create one with `/dca:plan` in VS Code.

Opens a tmux session named `run` with two panes: Claude Code executing the plan on the left, a shell for monitoring on the right.

```sh
dca run .
dca run ~/experiments/myrepo-feature
dca run . --remove-existing-container
```

If Claude Code is already running in the container, `dca run` exits with an error. If a previous session was interrupted (detected via `OUTCOME.md`), it prompts to resume before starting.

### `dca config <command>`

Manage the stored devcontainer default features that `dca devcontainer` injects via `--additional-features`. Features are read from any VS Code-compatible `settings.json` and stored in `~/.config/dca/config.json`.

| Command | Description |
|---------|-------------|
| `import <file>` | Read `dev.containers.defaultFeatures` from `<file>` and store it |
| `import-vscode` | Import from VS Code user `settings.json` |
| `import-cursor` | Import from Cursor user `settings.json` |
| `show` | Print stored features as JSON |
| `clear` | Remove stored features |

```sh
# Import from VS Code settings
dca config import-vscode

# Import from Cursor settings
dca config import-cursor

# Import from any settings.json
dca config import ~/my-settings.json

# View what's stored
dca config show

# Remove stored features
dca config clear
```

## Planning and Execution Loop

`dca` ships two Claude slash commands that close the loop between a planning session in the VS Code Claude extension and an unattended execution session via `dca run`.

| Command | Environment | What it does |
|---|---|---|
| `/dca:plan` | VS Code Claude extension | Produces an approved plan through conversation, then exports it to `STANDALONE_PLAN.md` |
| `/dca:implement` | Claude Code CLI (`dca run`) | Reads `STANDALONE_PLAN.md` + `OUTCOME.md`, reconciles state, executes unattended, writes progress and a closing summary to `OUTCOME.md` |

`STANDALONE_PLAN.md` and `OUTCOME.md` live at the repo root and are gitignored by default.

### Why not just use Claude's plan mode?

Claude's built-in plan mode is session-scoped — the plan lives in the conversation context and disappears when the session ends. `dca run` starts fresh with no knowledge of what was discussed in VS Code.

`/dca:plan` bridges this gap. It produces a structured, approved plan through conversation, then exports it as `STANDALONE_PLAN.md` — a file that persists across the context boundary. `/dca:implement` reads `STANDALONE_PLAN.md` at the start of the execution session and can run unattended with full context.

### Example loop

`/dca:plan` is a closing command — run it at the end of a planning conversation, not the start. Discuss the goal, decisions, constraints, and unknowns with Claude first. When you're ready, `/dca:plan` resolves any remaining ambiguities, gets your approval, then writes `STANDALONE_PLAN.md`.

```
# 1. Have a planning conversation in VS Code Claude extension
#    Discuss the goal, decisions, constraints, and unknowns with Claude.
#    Work through the problem until you're ready to hand off to execution.

# 2. Export the approved plan
/dca:plan
# → surfaces and resolves ambiguities, presents the plan inline, asks
#   "Save this DCA plan?", then writes STANDALONE_PLAN.md on confirmation

# 3. Run unattended
dca run .
# → starts the container, splits tmux into two panes, runs /dca:implement
#   in one (Claude Code executing the plan) and a shell in the other

# 4. Back in VS Code, plan the next iteration
/dca:plan
# → reads OUTCOME.md (completed, blocked, discovered), resolves new
#   ambiguities, writes the next section of STANDALONE_PLAN.md
```

If a session is interrupted or crashes, the next `dca run` detects the incomplete OUTCOME.md, prompts to resume, and picks up from the furthest safe point.

The commands are installed to `~/.claude/commands/` by `install.sh` and are available globally in any project.

> **Note:** The command files use colons in their filenames (`dca:plan.md`, `dca:implement.md`). Some `tar` implementations have trouble with colons when building archives. If you are packaging a release, verify that your tar version handles these filenames correctly.

## Requirements

- Git
- VS Code with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- A project with `devcontainer.json` configured

## Workflow Example

```sh
# Fork a repo for an experiment
dca fork ~/projects/myrepo ~/experiments/myrepo-feature
cd ~/experiments/myrepo-feature

# Plan in VS Code Claude extension, then export the plan
# /dca:plan

# Run the plan unattended
dca run .
# → Claude Code executes in one tmux pane, shell in the other
# → writes OUTCOME.md as it goes

# When done, discard the fork
rm -rf ~/experiments/myrepo-feature
```

## Installation

### One-liner (macOS/Linux)

```sh
curl -fsSL https://raw.githubusercontent.com/raginjason/dca/main/install.sh | sh
```

The install script will:
1. Fetch the latest release from GitHub
2. Install scripts to `~/.local/bin` (no sudo) or `/usr/local/bin`
3. Warn if the install directory is not in your `$PATH`

Override the install directory:

```sh
curl -fsSL https://raw.githubusercontent.com/raginjason/dca/main/install.sh | DCA_INSTALL_DIR=~/bin sh
```

### Manual

Download the latest release tarball from [Releases](https://github.com/raginjason/dca/releases), extract, and add to your `$PATH`:

```sh
tar -xzf dca-<version>.tar.gz -C ~/.local/bin
chmod +x ~/.local/bin/dca ~/.local/bin/dca-fork ~/.local/bin/dca-code ~/.local/bin/dca-cursor ~/.local/bin/dca-devcontainer ~/.local/bin/dca-config ~/.local/bin/dca-session ~/.local/bin/dca-run
```

### From source

```sh
git clone https://github.com/raginjason/dca.git
export PATH="/path/to/dca:$PATH"
```

## License

MIT
