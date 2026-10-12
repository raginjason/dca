# 2. Use adr-tools to manage ADRs

Date: 2026-10-11

## Status

Accepted

Amends [1. Record architecture decisions](0001-record-architecture-decisions.md)

Amended by [4. Support Claude cloud as a second development environment](0004-support-claude-cloud-as-a-second-development-environment.md)

## Context

ADR 1 adopts Architecture Decision Records but does not say how they are
created or numbered. Doing this by hand invites inconsistent numbering,
filenames and status/link handling.

This project is a collection of bash scripts, and development happens in a
devcontainer (`.devcontainer/devcontainer.json`).

## Decision

We will use [adr-tools](https://github.com/npryce/adr-tools) (pinned to 3.0.0)
to create and link ADRs. It is plain bash, matching the rest of the project.

- ADRs live in `doc/adr/` (recorded in `.adr-dir`).
- adr-tools is installed by a local devcontainer feature,
  `.devcontainer/adr-tools/`, at image build time so it is cached in the
  image layers.
- Create a record with `adr new "Title"`; supersede one with
  `adr new -s <number> "Title"`.

## Consequences

- Contributors working in the devcontainer get `adr` on their `PATH`
  automatically.
- Contributors outside the devcontainer can install adr-tools themselves
  or edit the Markdown by hand following the same template.
- Building the image needs network access to GitHub to fetch adr-tools.
