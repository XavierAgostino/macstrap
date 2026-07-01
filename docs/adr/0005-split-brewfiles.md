# 5. Split Brewfiles by role

Date: 2026-06-30

Status: Accepted

## Context

A single Brewfile forces every machine to install the same software. A work
machine should not carry personal or academic tooling, and a personal machine
should not carry work-only tooling. Users also want to opt out of GUI apps
entirely (CI, remote Macs).

## Decision

Split the Brewfile by role: `Brewfile.core` (the shared, always-installed
toolchain), `Brewfile.apps` (the GUI starter set, driven by `apps.catalog`), and
`Brewfile.personal` / `Brewfile.work` (profile extras). The installer composes
`core` plus the app selection plus the active profile's file.

## Consequences

- Each machine installs only what it needs, chosen by profile and mode.
- App selection can be default, interactive, an explicit list, or skipped.
- Homebrew Bundle stays the backend, so files are declarative desired state.
