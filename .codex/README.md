# Codex Project Setup

This directory contains the minimal project-scoped Codex setup.

## Files

- `config.toml`: safe project defaults for local work.
- `rules/default.rules`: command policy for risky actions.
- `templates/gccd-brief.md`: short template for framing future tasks.

## Current Scope

The repository now targets macOS environment setup. Agents may edit setup files, but must not run installers or host-changing commands unless the user explicitly asks to apply them.

## Add Later

Add skills, hooks, custom agents, or more templates only when an actual repeated workflow appears.
