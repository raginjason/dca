# dca — Dev Container A\*

Fast setup for experimental work in isolated devcontainers.

> The `dc` stands for devcontainer. The `a` stands for AI, anarchy, or asylum — depending on the mood.

## Why

Quickly fork a repo and launch VS Code in a disposable devcontainer. No impact on your primary working tree. Perfect for agentic workflows that run in isolation.

## Quick Start

```sh
# Fork a repo efficiently (shares git objects, minimal disk usage)
dca fork ~/original ~/experiment

# Launch in VS Code devcontainer
dca code .

# Use git normally inside container
git branch -b feature-x
git add/commit/push as usual
```

## Commands

```
usage: dca <command> [<args>]

fork and setup
   fork           Fork repo efficiently using git references

launch and develop
   code           Open directory in VS Code devcontainer
   devcontainer   Start a devcontainer with stored defaultFeatures injected
   session        Start a devcontainer with tmux and attach to a session

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

## Requirements

- Git
- VS Code with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- A project with `devcontainer.json` configured

## Workflow Example

```sh
# Start with an existing repo
cd ~
git clone https://github.com/user/myproject.git original

# Fork it for an experiment
dca fork original experiments/feature-x
cd experiments/feature-x

# Launch in devcontainer
dca code .

# Inside VS Code (running in container):
git branch -b feature-x
# - Agent makes changes, runs tests, commits
# - Everything is sandboxed in the container
# - No impact on your original working tree

# When done, just delete the fork
cd ~
rm -rf experiments/feature-x
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
chmod +x ~/.local/bin/dca ~/.local/bin/dca-fork ~/.local/bin/dca-code
```

### From source

```sh
git clone https://github.com/raginjason/dca.git
export PATH="/path/to/dca:$PATH"
```

## License

MIT
