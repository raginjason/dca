# 5. Keep cloud environment network requirements in the repo

Date: 2026-10-15

## Status

Accepted

Amends [4. Support Claude cloud as a second development environment](0004-support-claude-cloud-as-a-second-development-environment.md)

## Context

A Claude cloud environment's network policy, including its allowed domains, is
edited in the environment settings UI. There is no documented API or file for
it, so it cannot be managed as code, and a copy of the required hosts written
into documentation goes stale. Setup downloads from GitHub, apt and the
devcontainer base image registry, so an environment with a restricted network
policy fails at session start with an unhelpful download error if a host is
missing. We expect to share the repository with a team who will create their
own environments.

## Decision

We will keep the list of hosts that setup needs in one file in the repo,
`.devcontainer/dev-tools/hosts.txt`, and check it from both sides.

- `install.sh --hosts` prints the list for pasting into an environment's
  allowed domains. Documentation points to that command and does not copy the
  list.
- `install.sh --preflight` tests that each host is reachable and names any the
  network policy blocks. The Claude cloud SessionStart hook runs it before
  installing and only warns.
- CI fails if a setup file references a host missing from `hosts.txt`
  (`check-hosts-listed.sh`), and runs `--preflight` so the listed hosts are
  known to be valid.

## Consequences

- Adding a download from a new host means adding it to `hosts.txt`, and CI
  enforces that.
- The environment's allowlist itself still lives in the UI. If someone removes
  a host there, it is found when a session starts, not prevented.
- The preflight adds a few seconds, with short timeouts, to session start.
- The list can only name hosts the setup files mention directly. A host that a
  download redirects to (such as `release-assets.githubusercontent.com`) must
  be added by hand when it changes.
