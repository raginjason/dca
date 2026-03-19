# dca — Dev Container Agent/Anarchy/Asylum

Fast setup for experimental work in isolated devcontainers.

> The `dc` stands for devcontainer. The `a` stands for AI, anarchy, or asylum — depending on your mood.

**For installation and shell completion setup, see [INSTALLATION.md](INSTALLATION.md).**

## Why

Quickly fork a repo and launch VS Code in a disposable devcontainer. No impact on your primary working tree. Perfect for agentic workflows that run in isolation.

## Quick Start

```sh
# Fork a repo efficiently (shares git objects, minimal disk usage)
dca fork ~/my-proj ~/my-proj-feature

# Launch in VS Code devcontainer
dca code ~/my-proj-feature

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

# Launch in devcontainer
dca code experiments/feature-x

# Inside VS Code (running in container):
git branch -b feature-x
# - Agent makes changes, runs tests, commits
# - Everything is sandboxed in the container
# - No impact on your original working tree

# When done, just delete the fork
cd ~
rm -rf experiments/feature-x
```

## License

MIT
