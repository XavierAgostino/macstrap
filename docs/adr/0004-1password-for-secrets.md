# 4. 1Password for secrets and commit signing

Date: 2026-06-30

Status: Accepted

## Context

A setup tool must never leak secrets into a public repo, and professional repos
increasingly expect signed commits. Storing secrets in files (even gitignored
ones) is fragile, and GPG key management is clunky.

## Decision

Use [1Password](https://1password.com) as the secret backend. The repo stores
`op://` references and templates only; real values are injected at apply time. A
`gitleaks` pre-commit hook enforces that no secret is ever committed. Commit
signing uses an SSH key held in 1Password, signed through `op-ssh-sign` with a
biometric prompt per use.

## Consequences

- No secret material lives on disk in plaintext or in git history.
- Commits show the Verified badge on GitHub; the private key never leaves
  1Password.
- Committing requires 1Password to be unlocked (a quick Touch ID prompt), which
  is an accepted trade-off.
