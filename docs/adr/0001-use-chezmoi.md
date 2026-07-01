# 1. Use chezmoi for dotfile management

Date: 2026-06-30

Status: Accepted

## Context

A dotfiles system needs one source of truth that works across more than one
machine, handles per-machine differences (a personal laptop and a locked-down
work machine), and keeps secrets out of git. Plain symlink farms (bare git repo,
GNU stow) manage files but cannot template content or branch behavior by machine,
and they have no secret story.

## Decision

Use [chezmoi](https://chezmoi.io) as the source of truth. Configs live as
templates; per-machine data (profile, name, email) is supplied at
`chezmoi init` and stored in machine-local config that is never committed.
Secrets are injected at apply time from 1Password.

## Consequences

- One `main` branch configures any machine; a fresh Mac is a couple of commands.
- Files use chezmoi naming (`dot_`, `private_`, `.tmpl`); you edit through
  `chezmoi edit` rather than the live file.
- Templating enables the personal/work profile model (see ADR 0003).
