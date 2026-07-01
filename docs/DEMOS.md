# Demos

macstrap's README GIFs are generated from scripts, not screen-recorded. That
keeps them clean, consistent, and safe to regenerate — the demos are **scripted
and non-mutating**: they never install Homebrew, clone the repo, or change your
machine.

## Anatomy

```text
demo/
├── scripts/         scripted walkthroughs (the source of truth)
│   ├── lib.sh       shared branding helpers (colors, prompt, sections)
│   ├── 00-hero.sh   preview -> app picker -> doctor
│   ├── 02-app-picker.sh
│   ├── 03-cli-picker.sh
│   └── 04-doctor.sh
├── tapes/           VHS .tape files (one per GIF)
└── record.sh        regenerate GIFs from the tapes
```

Each tape drives a script through [`macstrap demo`](../demo/README.md), so the
recording and what a user sees when they run `macstrap demo` are the same thing.

The one exception is `tapes/tui.tape`, which records the **real Go TUI**
(`cmd/macstrap`) navigating its read-only screens — dashboard, Doctor, the app
picker, Report, Security. It builds the binary to a temp dir, puts it first on
`PATH`, and never confirms a picker, so it stays non-mutating like the rest.

## Watch locally (no recording)

```bash
macstrap demo          # hero
macstrap demo apps
macstrap demo cli
macstrap demo doctor
```

Set `DEMO_SPEED=0` to strip the pauses (useful in tests):

```bash
DEMO_SPEED=0 macstrap demo hero
```

## Regenerate the GIFs

```bash
brew bundle --file=brew/Brewfile.dev   # installs vhs, shellcheck, shfmt
./demo/record.sh                       # all GIFs -> .github/assets/
./demo/record.sh hero                  # just one (hero|apps|cli|doctor|tui)
```

Real, full install logs (`Downloading… Pouring… Already installed…`) belong in
[TROUBLESHOOTING.md](TROUBLESHOOTING.md), not the demos — the README should show
the experience (preview → pick → verify), not watch Homebrew for six minutes.

## Adding a demo

1. Add `demo/scripts/NN-name.sh` (source `lib.sh`; keep it non-mutating).
2. Register it in the `demo)` case in [`bin/macstrap`](../bin/macstrap).
3. Add `demo/tapes/name.tape` and a `record` entry in `demo/record.sh`.
4. `shellcheck` and `shfmt` cover `demo/scripts/` in CI — run them before pushing.
