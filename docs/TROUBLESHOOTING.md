# Troubleshooting and recovery

## chezmoi

**"config file template has changed, run chezmoi init to regenerate"**
A harmless warning after editing `.chezmoi.toml.tmpl`. Regenerate:
```bash
chezmoi init --source="$HOME/Developer/workspaces/macstrap"
```

**`chezmoi verify` reports drift, or a managed file changed unexpectedly**
```bash
chezmoi diff            # see what differs
chezmoi apply           # re-apply source to $HOME (source wins)
chezmoi re-add          # or pull a live edit back into the source
```

**Re-prompt for profile or identity**
Edit `~/.config/chezmoi/chezmoi.toml` directly, or run `chezmoi init` after
clearing the relevant `[data]` keys.

## Shell

**A new shell errors, or a tool is not found**
Open a fresh login shell and check resolution:
```bash
exec zsh
doctor
```
`node` and `npm` come from mise. Confirm with `mise ls` and `mise doctor`.

**`grep` behaves oddly in the terminal**
`grep` is aliased to `rg` for interactive use only. Use `command grep` or
`\grep` for classic behavior. Scripts are unaffected, since they use
`/usr/bin/grep`.

**conda command not found**
conda is lazy-loaded. Run `conda` once to initialize it (requires a conda
install such as miniconda).

## Homebrew

**`brew bundle check` says packages are missing**
Usually this means a package is outdated (an update is available) or was
installed outside Homebrew (for example a manually installed app or font). Run
`brew bundle --file=brew/Brewfile.core` to reconcile.

## Git

**Commits use the wrong identity**
Check `git config user.email`. On a personal machine that also has work repos,
set `workEmail` and `workDir` in chezmoi config (see
[work-separation.md](work-separation.md)).

**Signing fails ("failed to sign data")**

> [!IMPORTANT]
> Commit signing requires 1Password to be running and unlocked. The signer is
> `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`. Bypass a single
> commit with `git commit --no-gpg-sign`.

## Full reset

Everything is reproducible. To rebuild from scratch:
```bash
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

Preview any run first with `DRY_RUN=1`, and check machine state with
`bash scripts/dev-doctor.sh --json`.

## Restore a single dotfile

Managed files come from the source, so:
```bash
chezmoi apply ~/.zshrc      # restore one file from the source
```
