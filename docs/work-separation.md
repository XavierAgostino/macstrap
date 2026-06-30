# Work vs. Personal separation

How this dotfiles setup keeps a personal machine and the work machine
cleanly separated, and the guardrails to respect on a company-issued laptop.

## The profile model

`chezmoi init` asks for a **profile** (`personal` or `work`) plus name/email.
That single choice drives everything machine-specific:

| Data var | personal machine | work machine (work) |
|---|---|---|
| `profile` | `personal` | `work` |
| `email` | personal Gmail | **work work email** |
| `signingKey` | empty (off) | work SSH signing key (optional) |
| Brewfile installed | `core` + `personal` | `core` + `work` |

Because the work machine sets `email` to the work address, **every commit on
that machine is authored with the work identity by default** — no per-repo
fiddling required.

## Git identity

- Base identity = profile `name` + `email` (`~/.gitconfig`, templated).
- **Optional per-directory override** (`includeIf`): only relevant on a machine
  that hosts *both* personal and work repos. Set `workEmail` + `workDir` in
  `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply`. Repos under `workDir`
  then use `~/.config/git/work.gitconfig`. On a dedicated work machine you don't
  need this — the base identity is already the work one.

## SSH commit signing (work machine)

Signing gives the green **Verified** badge on GitHub and is increasingly expected
on professional repos. It's off until you set a key. To enable on the work
machine, with the company 1Password:

1. **Enable the 1Password SSH agent**: 1Password → Settings → Developer → *Use
   the SSH agent*. Required — `op-ssh-sign` reaches the key through the agent.
2. **Create the signing key** (CLI or app). CLI:
   ```bash
   op item create --category="SSH Key" --title="Git Commit Signing" \
     --vault="<your vault>" --ssh-generate-key=ed25519
   op read "op://<your vault>/Git Commit Signing/public key"
   ```
   On the work machine use the **company vault**.
3. **Make sure the agent serves it.** The agent only enables the `Private` vault
   by default. If the key is in another vault, add it to
   `~/.config/1Password/ssh/agent.toml` (above the `Private` entry):
   ```toml
   [[ssh-keys]]
   item = "Git Commit Signing"
   vault = "<your vault>"
   ```
   Verify: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l`
   should list the key.
4. **Turn on signing** in chezmoi and apply:
   ```bash
   chezmoi edit-config        # set signingKey = "ssh-ed25519 AAAA..."
   chezmoi apply
   ```
   This sets `gpg.format=ssh`, `commit.gpgsign=true`, `op-ssh-sign` as signer, and
   an `allowed_signers` file for local verification.
5. **Register on GitHub** — add the **public** key as a *Signing key*
   (https://github.com/settings/ssh/new → key type **Signing**), or via CLI:
   ```bash
   gh auth refresh -h github.com -s admin:ssh_signing_key
   echo "<public key>" | gh ssh-key add - --type signing --title "Git Commit Signing"
   ```
   > Gotcha: if the 1Password `gh` shell plugin is active (`gh` is an alias for
   > `op plugin run -- gh`), it injects a stored PAT that overrides your keyring
   > scopes — `gh ssh-key add` then 404s for the signing scope. Bypass it for
   > this one-off with `command gh ...` (uses native keyring auth).
6. Verify: `git log --show-signature -1` → "Good signature"; pushed commits show
   **Verified** on GitHub.

> Commits now require **1Password unlocked** (Touch ID prompt). If 1Password is
> locked/quit, signing — and thus committing — fails until you unlock. Bypass a
> single commit with `git commit --no-gpg-sign`.

## GitHub CLI — multiple accounts

`gh` supports several accounts at once (you already have a personal one):

```bash
gh auth login                 # add the work GitHub account
gh auth switch                # switch active account
gh auth status                # see all logged-in accounts
```
Use the work account for work repos. For HTTPS pushes, `gh` manages the
credential per account. Keep personal and work auth distinct.

## Compliance guardrails (company laptop)

These are good-citizen defaults; always defer to your company's actual IT/security
policy where it differs.

- **Work code stays on the work machine.** Don't clone company repos onto the
  personal Mac or push them to personal GitHub/cloud.
- **Separate identities everywhere** — git email, GitHub account, and ideally a
  separate **browser profile** for work vs personal.
- **Don't sign into personal accounts you don't need** on the work machine
  (personal email, personal cloud, personal password vault). Company secrets go
  in the **company 1Password**, not your your personal vaults.
- **Secrets never hit git.** This repo stores `op://` references and templates
  only; the gitleaks pre-commit hook enforces it.
- **Respect MDM.** If the machine is managed (Jamf/Kandji), let IT-managed tools
  (VPN, security agents) be installed by IT — don't fight or remove them.
