# Troubleshooting & recovery

## chezmoi

**"config file template has changed, run chezmoi init to regenerate"**
Harmless warning after editing `.chezmoi.toml.tmpl`. Regenerate:
```bash
chezmoi init --source="$HOME/Developer/workspaces/macstrap"
```

**`chezmoi verify` reports drift / a managed file changed unexpectedly**
```bash
chezmoi diff            # see what differs
chezmoi apply           # re-apply source -> $HOME (source wins)
# or pull a live edit back INTO the source:
chezmoi re-add
```

**Re-prompt for profile/identity**
Edit `~/.config/chezmoi/chezmoi.toml` directly, or
`chezmoi init` after clearing the relevant `[data]` keys.

## Shell

**New shell errors or a tool isn't found**
Open a fresh login shell and check resolution:
```bash
exec zsh
doctor
```
`node`/`npm` come from mise — confirm with `mise ls` and `mise doctor`.

**`grep` behaves oddly in the terminal**
`grep` is aliased to `rg` (interactive only). Use `command grep` or `\grep` for
classic behavior; scripts are unaffected (they use `/usr/bin/grep`).

**conda command not found**
It's lazy-loaded — just run `conda` once and it initializes (requires
`~/miniconda3`).

## Homebrew

**`brew bundle check` says packages are missing**
Usually means *outdated* (an update is available) or installed outside brew
(e.g. a manually-installed app/font). Run `brew bundle --file=brew/Brewfile.core`
to reconcile. Not an error in the split itself.

## Git

**Commits use the wrong identity**
Check `git config user.email`. On a personal machine that also has work repos,
set `workEmail`/`workDir` in chezmoi config (see `work-separation.md`).

**Signing fails ("failed to sign data")**
Ensure 1Password is running and the SSH key/agent is set up; the signer is
`/Applications/1Password.app/Contents/MacOS/op-ssh-sign`. Disable temporarily
with `git commit --no-gpg-sign`.

## Full recovery

Everything is reproducible. To rebuild from scratch:
```bash
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```
To roll back to the pre-modernization state, the tag
`pre-modernization-2026-06-30` on the repo captures the original setup.

## Restore a single dotfile

Managed files come from the source, so:
```bash
chezmoi apply ~/.zshrc      # restore one file from source
```
