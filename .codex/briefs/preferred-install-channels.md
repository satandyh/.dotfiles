# Preferred Installation Channels

## Goal

Install every program in the repository through an appropriate, repeatable macOS channel without reinstalling apps that are already present.

## Context

`Brewfile` is the declarative package catalog, `install.sh` orchestrates Homebrew and Mac App Store installation, and the shell tests exercise the workflow without changing the real Mac.

## Constraints

- Keep application settings unchanged in this iteration; Raycast settings are deferred.
- Do not upgrade, adopt, or reinstall existing applications.
- Do not bypass macOS security checks.
- An optional application failure must not prevent the terminal setup from completing.
- Do not run the real installer or push changes.

## Done When

- Every catalog entry has a documented installation channel.
- Lang Switcher uses the Mac App Store and the remaining casks use official upstream artifacts.
- ChatGPT and Claude are installed as desktop applications without their command-line tools.
- Flameshot failure is isolated and reported for manual follow-up.
- Isolated smoke and guard tests pass.
