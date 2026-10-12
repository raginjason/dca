# 4. Support Claude cloud as a second development environment

Date: 2026-10-11

## Status

Accepted

Amends [2. Use adr-tools to manage ADRs](0002-use-adr-tools-to-manage-adrs.md)

Amends [3. Use devcontainers for the development environment](0003-use-devcontainers-for-the-development-environment.md)

## Context

Work on dca is also done in Claude Code on the web (Claude cloud), which runs
sessions in a managed container that cannot run devcontainers or their
features. It starts from a plain image without our tooling.

Supporting a second environment risks the two diverging. If each installs
tools its own way, versions drift: the devcontainer features installed the
latest shellcheck and shfmt at build time (0.11.0 and 3.14.1 at the time of
writing), while Ubuntu's apt packages in Claude cloud give 0.9.0 and 3.8.0.
Lint and format results could then differ between environments, and the
devcontainer's own result changed whenever its image was rebuilt. The base
operating systems also differed (Debian in the devcontainer, Ubuntu 24.04 in
Claude cloud).

We cannot change or reproduce the Claude cloud image, so the devcontainer is
the side that has to move to match it.

## Decision

We will support Claude cloud as a second, equally supported development
environment, so there are two: the devcontainer and Claude cloud. The
devcontainer remains the primary environment (ADR 3), and Claude cloud must be
kept aligned with it.

- Claude cloud is provisioned by a `SessionStart` hook
  (`.claude/hooks/session-start.sh`, registered in `.claude/settings.json`)
  that runs when `CLAUDE_CODE_REMOTE=true`.
- The devcontainer base image tracks the Claude cloud operating system
  (`mcr.microsoft.com/devcontainers/base:ubuntu-24.04`). When Claude cloud
  moves to a new Ubuntu release, the devcontainer base moves with it.
- Both environments install tools with one script,
  `.devcontainer/dev-tools/install.sh`, at versions pinned in
  `.devcontainer/dev-tools/versions.env`. It is a local devcontainer feature
  (`./dev-tools`) and is also run by the hook. It replaces the `adr-tools`
  feature and the `devcontainers-extra` shellcheck and shfmt features, and so
  supersedes the install route described in ADR 2.
- Tools come from upstream release binaries (adr-tools from its git tag), not
  from apt, so versions do not depend on the base image's distribution.
- `gh` is pinned too but installed only where it is missing. Claude cloud
  ships its own proxy-configured `gh`, which is left alone and only reported.
- Upgrading a tool means editing `versions.env`; both environments pick it up.
- The script skips a tool already at its pinned version.
- Drift is checked by `install.sh --check`, which compares installed tool
  versions with `versions.env` and the OS with the devcontainer base image.
  The Claude cloud hook runs it at every session start and prints warnings
  without blocking. CI cannot see Claude cloud, so a GitHub Action instead
  installs the tools on `ubuntu-24.04` and runs the same check, which keeps
  the installer itself working.

## Consequences

- Both environments run identical tool versions, and image rebuilds are
  reproducible.
- Adding a tool means editing one script. Anything else the project needs from
  the environment must work in both.
- The match is partial. Claude cloud ships extra preinstalled toolchains and
  runs as root, and its `gh` is not managed by us. Only the OS and the tools
  in `versions.env` are aligned.
- Cloud drift (a new Ubuntu release, a changed preinstalled `gh`) is reported
  at session start, not prevented, and only when someone reads the warning.
- Upgrades are manual. Release downloads are pinned by version but not
  checksum-verified.
- Session start in Claude cloud, and the devcontainer build, need network
  access to GitHub. The script installs `xz-utils` with apt if missing (for
  shellcheck's archive).
