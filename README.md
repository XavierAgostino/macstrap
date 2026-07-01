<div align="center">

<h1><picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/logos/apple-dark.svg"><img src=".github/assets/logos/apple-light.svg" height="26" alt=""/></picture>&nbsp; macstrap</h1>

### Bootstrap a modern macOS dev environment, in one command

[![CI](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

Reproducible, **profile-aware** macOS setup on **chezmoi** and **mise**. One repo
for personal and work machines — secrets never committed.

<br/>

<img src=".github/assets/demo.gif" width="780" alt="macstrap setup preview walkthrough"/>

</div>

---

## How it works

Set up a Mac or fork this repo — same flow:

```text
install once → pick a profile → dotfiles + runtimes + tools → health check → maintain
```

1. **Install once** — one-liner installs Homebrew, clones the repo, links `macstrap` onto PATH.
2. **Pick a profile** — `personal` or `work` drives git identity, packages, and signing.
3. **Configure** — dotfiles ([chezmoi](https://chezmoi.io)), runtimes ([mise](https://mise.jdx.dev)), core toolchain, apps, health check. Idempotent.
4. **Add tools on demand** — `macstrap apps` / `macstrap cli`; selections replay on the next Mac.
5. **Maintain** — `macstrap doctor`, `macstrap diff`, `macstrap apply`, `macstrap update`, `macstrap report`.

Preview with `macstrap install --dry-run`. Revert with `macstrap uninstall`. Identity and keys stay in machine-local config.

## Quick start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/XavierAgostino/macstrap/main/install.sh)"
```

Open a new terminal:

```bash
macstrap install              # default stack (asks: personal or work?)
macstrap install --minimal    # shell, git, chezmoi, mise, CLI core only
macstrap install --work --apps
macstrap doctor               # health check
macstrap apps                 # pick GUI apps
macstrap cli                  # pick optional project CLIs
macstrap update               # pull latest and apply
```

Full walkthrough: [`docs/SETUP.md`](docs/SETUP.md).

> [!TIP]
> Dry run: `macstrap install --dry-run`. Quiet by default — add `--verbose` for full output.

### The TUI

Run `macstrap` with no arguments — dashboard, Doctor, searchable Apps/CLI pickers,
Report, Security, Logs, and an Install dry-run preview.

```bash
macstrap            # interactive dashboard
macstrap doctor     # scriptable — add --json for machines
macstrap logs       # step logs from the last run
```

<div align="center">
<img src=".github/assets/demo-tui.gif" width="780" alt="macstrap TUI — dashboard, doctor, searchable pickers, report, security, logs, install plan"/>
</div>

## See it in action

Scripted walkthroughs — `macstrap demo <name>` installs nothing:

| Demo | Command |
| --- | --- |
| Setup preview | `macstrap demo` |
| App picker | `macstrap demo apps` |
| CLI picker | `macstrap demo cli` |
| Doctor | `macstrap demo doctor` |

**App picker**

<div align="center">
<img src=".github/assets/demo-apps.gif" width="780" alt="macstrap interactive app picker"/>
</div>

**CLI picker**

<div align="center">
<img src=".github/assets/demo-cli.gif" width="780" alt="macstrap optional CLI picker"/>
</div>

**Doctor**

<div align="center">
<img src=".github/assets/demo-doctor.gif" width="780" alt="macstrap doctor health check"/>
</div>

CLI catalog (groups and install commands): [`docs/SETUP.md` §6](docs/SETUP.md#6-optional-clis-per-project-not-per-machine).
Regenerate GIFs: [`docs/DEMOS.md`](docs/DEMOS.md).

<details>
<summary><b>Manual setup and env vars</b></summary>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
git clone https://github.com/XavierAgostino/macstrap.git ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

Env vars for agents and CI: `MODE=minimal|default|interactive|headless|doctor`,
`PROFILE=personal|work`, `APPS=0|default|interactive|a,b,c`, `DRY_RUN=1`.
Example: `PROFILE=work APPS=cursor,orbstack bash scripts/bootstrap.sh`.
See [`docs/AGENT-USAGE.md`](docs/AGENT-USAGE.md).

</details>

## Profiles (personal vs work)

One profile at `chezmoi init` drives git identity, Brewfiles, and signing —
[`docs/work-separation.md`](docs/work-separation.md).

> [!IMPORTANT]
> With signing enabled, **1Password must be unlocked** to commit. Bypass once with
> `git commit --no-gpg-sign`.

## Make it yours

1. Fork this repo.
2. Edit `brew/Brewfile.*`, `dot_config/*`, and `ai/*`.
3. Run `REPO_SLUG=you/macstrap bash scripts/bootstrap.sh`.

Name, email, and signing keys live in machine-local chezmoi config — never committed.

## Maintenance

```bash
macstrap report        # what macstrap manages
macstrap security      # secrets, signing, hook posture
macstrap doctor --json # machine-readable health
macstrap uninstall     # dry-run back-out (--apply to perform)
```

`uninstall.sh` backs up before removing; it never touches Homebrew packages, 1Password, runtimes, or your data.

## Documentation

| If you… | Start here |
| --- | --- |
| Just installed | [`docs/SETUP.md`](docs/SETUP.md) |
| Work laptop | [`docs/work-separation.md`](docs/work-separation.md) |
| Fork / customize | [`docs/README.md`](docs/README.md) |
| Automate / agent | [`docs/AGENT-USAGE.md`](docs/AGENT-USAGE.md) |
| Something broke | [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) |

## License

[MIT](LICENSE)
