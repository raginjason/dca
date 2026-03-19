# Installation

## Requirements

- Git
- VS Code with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- A project with `devcontainer.json` configured

## Installing dca

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

### Manual Download

Download the latest release tarball from [Releases](https://github.com/raginjason/dca/releases), extract, and add to your `$PATH`:

```sh
tar -xzf dca-<version>.tar.gz -C ~/.local/bin
chmod +x ~/.local/bin/dca ~/.local/bin/dca-fork ~/.local/bin/dca-code
```

### From Source

Clone the repository and add `bin/` to your `$PATH`:

```sh
git clone https://github.com/raginjason/dca.git
export PATH="/path/to/dca/bin:$PATH"
```

## Shell Completion

Enable tab completion for `dca` in bash or zsh.

### Bash

#### Simple (Source directly)

Add to `~/.bashrc`:

```sh
source /path/to/dca/completion/dca-completion.bash
```

#### System-wide

Copy bash completion to your system's completion directory:

```sh
cp /path/to/dca/completion/dca-completion.bash /usr/local/etc/bash_completion.d/dca
```

Then reload your shell or run `exec $SHELL`.

### Zsh

Zsh uses a built-in completion framework that must be initialized first. Choose one of the three installation methods:

#### 1. User-level Installation (Recommended)

Create a user completions directory and copy the completion file:

```sh
mkdir -p ~/.zsh/completions
cp /path/to/dca/completion/_dca ~/.zsh/completions/
```

Then add to `~/.zshrc`:

```sh
autoload -Uz compinit && compinit
fpath=(~/.zsh/completions $fpath)
```

This approach keeps completions isolated to your user and makes them portable across machines.

#### 2. System-wide Installation

Copy the completion file to the system completion directory:

```sh
sudo cp /path/to/dca/completion/_dca /usr/local/share/zsh/site-functions/
```

Then initialize the completion framework in `~/.zshrc`:

```sh
autoload -Uz compinit && compinit
```

The completion will be automatically available system-wide.

#### 3. Source Directly

Add to `~/.zshrc`:

```sh
autoload -Uz compinit && compinit
source /path/to/dca/completion/_dca
```

This is the simplest approach but requires maintaining the source path if you move the dca installation.
