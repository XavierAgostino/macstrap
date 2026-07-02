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
| `pink` | `#d996c8` | Active accent (fzf highlight, selection) |
| `pink_dim` | `#c892ab` | Prompt character, the single point of focus |
| `green` | `#8fb59c` | Success, installed, healthy |
| `peach` | `#e0b18f` | Docs, warnings, human attention |
| `red` | `#f4777f` | Errors, failed checks, destructive actions |
| `muted` | `#8a8a8a` | Git branch and metadata (ambient context), durations |
| `fg` | `#ffffff` | Normal, readable text (matches Ghostty Vesper) |
| `bg` | `#101010` | Background |

## Where it is applied

- **Ghostty** (`dot_config/ghostty/config`): `theme = Vesper` sets the ANSI
  palette that `eza` and terminal output inherit.
- **Starship** (`dot_config/starship.toml`): `directory = lavender` (leads),
  `git_branch = muted` and `git_status = lavender_dim` (ambient git context),
  prompt `= pink_dim` (the one accent), errors `= red`, `cmd_duration = muted`.
- **fzf** (`FZF_DEFAULT_OPTS` in `private_dot_zshrc.tmpl`): lavender prompt,
  pink highlight/pointer, green marker, muted info.
- **zsh-syntax-highlighting**: commands/paths = lavender, aliases = pink,
  strings = green, comments = muted, errors = red.
- **zsh-autosuggestions**: muted gray ghost text.
- **bat** (`dot_config/bat/config`): TwoDark theme (closest bundled match to Vesper).
- **delta** (`dot_gitconfig.tmpl`): minus = red, plus = green, file headers = lavender.
- **Cursor / VS Code** (`private_Library/.../User/settings.json`): Vesper theme,
  lifted UI chrome, Geist Mono, integrated terminal ANSI aligned with Ghostty;
  **Cmd+Shift+G** opens Ghostty as the external terminal.

## Readability

The default Ghostty config is opaque with no blur, so text stays high-contrast
(the common accessibility target is at least 4.5:1) on any wallpaper. Soft
translucency and blur are available as an opt-in "aesthetic mode" block in the
config: readable by default, pretty by choice.
