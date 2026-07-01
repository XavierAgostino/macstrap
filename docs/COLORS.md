# Color language

macstrap uses the [Vesper](https://github.com/raunofreiberg/vesper) palette with
a consistent, semantic meaning for every color. The goal is not just pretty
colors but a language: each color means one thing everywhere (prompt, `eza`,
`fzf`, git status), so the terminal is calm and easy to parse at a glance.

## The palette

| Role | Hex | Meaning |
| --- | --- | --- |
| `lavender` | `#a8a0cc` | Paths, directories, structure ("where am I") |
| `lavender_dim` | `#8f89aa` | Secondary structure (git status detail, borders) |
| `pink` | `#d996c8` | Active accent, current git branch ("what state") |
| `pink_dim` | `#c892ab` | Prompt character, focus |
| `green` | `#8fb59c` | Success, installed, healthy |
| `peach` | `#e0b18f` | Docs, warnings, human attention |
| `red` | `#f4777f` | Errors, failed checks, destructive actions |
| `muted` | `#8a8a8a` | Metadata, durations, inactive text |
| `fg` | `#eeeeee` | Normal, readable text |
| `bg` | `#101010` | Background |

## Where it is applied

- **Starship** (`dot_config/starship.toml`): `directory = lavender`,
  `git_branch = pink`, `git_status = lavender_dim`, prompt `= pink_dim`,
  errors `= red`, `cmd_duration = muted`.
- **fzf** (`FZF_DEFAULT_OPTS`): lavender prompt, pink highlight/pointer, green
  marker, muted info.
- **Ghostty** (`dot_config/ghostty/config`): `theme = Vesper` sets the ANSI
  palette that `eza`, `bat`, `delta`, and everything else inherit.

## Readability

The default Ghostty config is opaque with no blur, so text stays high-contrast
(the common accessibility target is at least 4.5:1) on any wallpaper. Soft
translucency and blur are available as an opt-in "aesthetic mode" block in the
config: readable by default, pretty by choice.
