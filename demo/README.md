# macstrap demos

Scripted, deterministic walkthroughs of the macstrap experience. They exist to
show the product cleanly — **they install nothing and change nothing on your
machine.** Each demo answers one question a new user has:

| Demo | Answers | Script |
| --- | --- | --- |
| `hero` | What is macstrap? | [`scripts/00-hero.sh`](scripts/00-hero.sh) |
| `apps` | Can I install only what I want? | [`scripts/02-app-picker.sh`](scripts/02-app-picker.sh) |
| `cli` | Can I add project tools later? | [`scripts/03-cli-picker.sh`](scripts/03-cli-picker.sh) |
| `doctor` | How do I know my machine is healthy? | [`scripts/04-doctor.sh`](scripts/04-doctor.sh) |

## Watch a demo

```bash
macstrap demo          # hero walkthrough
macstrap demo apps     # app picker
macstrap demo cli      # optional CLI picker
macstrap demo doctor   # health check
```

## Regenerate the README GIFs

The GIFs in `.github/assets/` are produced from the `.tape` files in
[`tapes/`](tapes) with [VHS](https://github.com/charmbracelet/vhs), so they are
repeatable and never hand-recorded.

```bash
brew bundle --file=brew/Brewfile.dev   # installs vhs
./demo/record.sh                       # regenerate all GIFs
./demo/record.sh hero                  # or just one
```

Because the tapes drive the scripts above (not live installs), re-recording is
safe and produces identical output every time. See
[`docs/DEMOS.md`](../docs/DEMOS.md) for the full workflow.
