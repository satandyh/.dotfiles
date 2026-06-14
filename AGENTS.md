# Repository Guidelines

## Purpose

This repository manages a lightweight macOS environment setup for Apple Silicon machines. It uses simple, repeatable scripts and clear configuration files instead of the previous Ansible/Linux dotfiles approach.

## Workflow

Use GCCD for new tasks:

- Goal: what should change or be created.
- Context: which files and facts matter.
- Constraints: what must not happen.
- Done when: what proves the task is complete.

Use `.codex/templates/gccd-brief.md` when a task needs a written brief.

## Boundaries

Keep changes inside this repository unless the user explicitly approves otherwise. Do not run installers, package managers, provisioning scripts, macOS `defaults` writes, or commands that alter the host OS unless the user specifically asks to apply the setup. Do not push to remotes.

## Style

Prefer quality and simplicity. Use native macOS/Homebrew mechanisms where they are clear and reliable. Avoid placeholder skills, hooks, agents, or extra templates until a repeated workflow proves they are needed.

## Context

Current primary files are `install.sh`, `Brewfile`, `config/`, `README.md`, `AGENTS.md`, and `.codex/`. The old Ansible implementation has been removed from the working tree.

Before finishing, verify by reading files and checking structure. Do not validate by running real installation or provisioning commands.
