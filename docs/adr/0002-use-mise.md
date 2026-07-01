# 2. Use mise for runtimes

Date: 2026-06-30

Status: Accepted

## Context

Language runtimes are a common source of "works on my machine" pain. Node in
particular often resolves from several places at once (nvm, Homebrew, a global
install), which is slow and ambiguous. Per-tool managers (nvm, pyenv, rbenv) each
add shell startup cost and their own conventions.

## Decision

Use [mise](https://mise.jdx.dev) as the single runtime manager for Node, Python,
and more. It reads `.nvmrc`, `.tool-versions`, and `mise.toml` per project, so
versions switch automatically on `cd`.

## Consequences

- One tool and one activation line replace the nvm/pyenv/rbenv stack.
- Existing `.nvmrc` and `.tool-versions` files keep working.
- Python packaging is still handled by `uv`; mise manages the interpreter.
