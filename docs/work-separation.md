# Work vs. personal separation

How this setup keeps a personal machine and a work machine cleanly separated,
and the guardrails to respect on a company-issued laptop.

## The profile model

`chezmoi init` asks for a profile (`personal` or `work`) plus name and email.
That single choice drives everything machine-specific:

| Data var | personal machine | work machine |
|---|---|---|
| `profile` | `personal` | `work` |
| `email` | personal email | work email |
| `signingKey` | empty (off) | work SSH signing key (optional) |
| Brewfiles installed | `core` + `apps` + `personal` | `core` + `apps` + `work` |

Because the work machine sets `email` to the work address, every commit on that
machine is authored with the work identity by default, with no per-repo fiddling.

## Git identity

- Base identity is the profile `name` and `email` (`~/.gitconfig`, templated).
- An optional per-directory override (`includeIf`) is useful only on a machine
  that hosts both personal and work repos. Set `workEmail` and `workDir` in
  `~/.config/chezmoi/chezmoi.toml`, then run `chezmoi apply`. Repos under
  `workDir` then use `~/.config/git/work.gitconfig`. On a dedicated work machine
  you do not need this, since the base identity is already the work one.

## SSH commit signing

Signing gives the green Verified badge on GitHub and is increasingly expected on
professional repos. It is off until you set a key. To enable it, with 1Password:

1. **Enable the 1Password SSH agent:** 1Password, Settings, Developer, "Use the
   SSH agent". This is required, because `op-ssh-sign` reaches the key through
   the agent.
2. **Create the signing key** (CLI or app). CLI:
   ```bash
   op item create --category="SSH Key" --title="Git Commit Signing" \
     --vault="<your vault>" --ssh-generate-key=ed25519
   op read "op://<your vault>/Git Commit Signing/public key"
   ```
   On a work machine, use the company vault.
3. **Make sure the agent serves the key.** The agent enables only the `Private`
   vault by default. If the key is in another vault, add it to
   `~/.config/1Password/ssh/agent.toml`, above the `Private` entry:
   ```toml
   [[ssh-keys]]
   item = "Git Commit Signing"
   vault = "<your vault>"
   ```
   Verify with
   `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l`;
   the key should be listed.
4. **Turn on signing** in chezmoi and apply:
   ```bash
   chezmoi edit-config        # set signingKey = "ssh-ed25519 AAAA..."
   chezmoi apply
   ```
   This sets `gpg.format=ssh`, `commit.gpgsign=true`, `op-ssh-sign` as the
   signer, and an `allowed_signers` file for local verification.
5. **Register on GitHub.** Add the public key as a Signing key at
   https://github.com/settings/ssh/new (key type Signing), or via CLI:
   ```bash
   gh auth refresh -h github.com -s admin:ssh_signing_key
   echo "<public key>" | gh ssh-key add - --type signing --title "Git Commit Signing"
   ```

   > [!NOTE]
   > If the 1Password `gh` shell plugin is active (so `gh` is an alias for
   > `op plugin run -- gh`), it injects a stored token that overrides your
   > keyring scopes, and `gh ssh-key add` returns a 404 for the signing scope.
   > Bypass it for this one-off with `command gh ...`, which uses native keyring
   > auth.

6. Verify with `git log --show-signature -1` (it should report "Good
   signature"). Pushed commits then show Verified on GitHub.

> [!IMPORTANT]
> With signing on, commits are signed through 1Password, so 1Password must be
> unlocked to commit (a quick Touch ID prompt). If it is locked or quit,
> committing fails until you unlock. Bypass a single commit with
> `git commit --no-gpg-sign`.

## GitHub CLI: multiple accounts

`gh` supports several accounts at once:

```bash
gh auth login                 # add the work GitHub account
gh auth switch                # switch the active account
gh auth status                # list logged-in accounts
```

Use the work account for work repos. For HTTPS pushes, `gh` manages the
credential per account. Keep personal and work auth distinct.

## Compliance guardrails (company laptop)

These are good-citizen defaults. Always defer to your company's actual IT and
security policy where it differs.

- **Work code stays on the work machine.** Do not clone company repos onto a
  personal Mac or push them to personal GitHub or cloud.
- **Separate identities everywhere:** git email, GitHub account, and ideally a
  separate browser profile for work and personal.
- **Do not sign into personal accounts you do not need** on the work machine.
  Company secrets belong in the company 1Password, not a personal vault.
- **Secrets never hit git.** This repo stores `op://` references and templates
  only; the gitleaks pre-commit hook enforces it.
- **Respect MDM.** If the machine is managed (Jamf, Kandji), let IT-managed tools
  such as VPN and security agents be installed by IT. Do not fight or remove them.
