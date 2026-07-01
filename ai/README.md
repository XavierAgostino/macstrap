# AI assistant config

Starter instructions for AI coding assistants (Claude Code, Codex, Cursor, …).
Repo-only (chezmoi does not apply these to `$HOME`): deploy deliberately so you
never clobber an existing `~/.claude/CLAUDE.md`. **Customize them to your style.**

| File | Purpose | Deploy to |
| --- | --- | --- |
| `engineering-practices.md` | Portable "how I engineer" layer, the source the others derive from. | (reference) |
| `CLAUDE.example.md` | Self-contained global instructions example. | `~/.claude/CLAUDE.md` |
| `AGENTS.md` | Tool-agnostic conventions for Codex/Cursor/other agents. | repo root or `~/.codex/AGENTS.md` |
| `claude-settings.json` | Clean Claude Code settings baseline. | `~/.claude/settings.json` (merge) |

## Deploy

```bash
mkdir -p ~/.claude
cp ai/CLAUDE.example.md ~/.claude/CLAUDE.md       # then edit to taste
cp ai/claude-settings.json ~/.claude/settings.json
```

These are a *starting point*, the whole value is making them sound like you.
