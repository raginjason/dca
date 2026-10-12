# 3. Use devcontainers for the development environment

Date: 2026-10-11

## Status

Accepted

## Context

dca is itself a tool for working in devcontainers, and contributors need a
reproducible environment with the same shell tooling (shellcheck, shfmt,
adr-tools, GitHub CLI).

## Decision

We will use a devcontainer (`.devcontainer/devcontainer.json`) as the
primary development environment.

## Consequences

- Tooling is declared once, as devcontainer features, and is identical for
  every contributor.
- Contributors need Docker and a devcontainer-capable editor or the
  devcontainer CLI.
