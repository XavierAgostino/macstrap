# Demos

README GIFs are generated from scripts, not screen-recorded. Demos are **scripted
and non-mutating** — they never install Homebrew, clone the repo, or change your
machine.

## Anatomy

```text
demo/
├── scripts/         walkthroughs (source of truth)
│   ├── lib.sh       branding helpers
│   ├── 00-hero.sh   preview → app picker → doctor
│   ├── 02-app-picker.sh
│   ├── 03-cli-picker.sh
│   └── 04-doctor.sh
├── tapes/           VHS .tape files (one per GIF)
└── record.sh        regenerate GIFs
```

Shell demos run via `macstrap demo`. `tapes/tui.tape` records the real Go TUI
(read-only screens only — no confirmed installs).

## Watch locally

```bash
macstrap demo          # hero
macstrap demo apps
macstrap demo cli
macstrap demo doctor
```

`DEMO_SPEED=0` strips pauses (useful in tests).

## Regenerate GIFs

```bash
brew bundle --file=brew/Brewfile.dev   # vhs, shellcheck, shfmt
./demo/record.sh                       # all GIFs → .github/assets/
./demo/record.sh hero                  # one: hero|apps|cli|doctor|tui
```

Full install logs belong in [TROUBLESHOOTING.md](TROUBLESHOOTING.md), not demos.

## Demo scripts

| Demo | Question | Script |
| --- | --- | --- |
| `hero` | What is macstrap? | [`scripts/00-hero.sh`](../demo/scripts/00-hero.sh) |
| `apps` | Install only what I want? | [`scripts/02-app-picker.sh`](../demo/scripts/02-app-picker.sh) |
| `cli` | Add project tools later? | [`scripts/03-cli-picker.sh`](../demo/scripts/03-cli-picker.sh) |
| `doctor` | Is my machine healthy? | [`scripts/04-doctor.sh`](../demo/scripts/04-doctor.sh) |

## Adding a demo

1. Add `demo/scripts/NN-name.sh` (source `lib.sh`; non-mutating).
2. Register in the `demo)` case in [`bin/macstrap`](../bin/macstrap).
3. Add `demo/tapes/name.tape` and a `record` entry in `demo/record.sh`.
4. Run `shellcheck` and `shfmt` before pushing (CI enforces both).
