# macOS Environment Setup

This repository prepares a lightweight macOS development and management environment for Apple Silicon machines. It replaces the old Ansible/Linux setup with a simple installer, a `Brewfile`, and a few managed config files.

## What It Installs

- Homebrew if missing.
- CLI tools: `git`, `curl`, `htop`, `tmux`, `starship`, `fzf`, and zsh helper plugins.
- Apps and fonts through Homebrew Cask: Ghostty, VS Code, Chrome, Google Drive, Yandex Disk, KeePassXC, Claude, Codex, Flameshot, and Fira Code Nerd Font.

## What It Configures

- zsh history, completions, autosuggestions, syntax highlighting, fzf integration, and Starship prompt.
- Ghostty with Fira Code, light transparency, padding, and a small dark color set.
- Starship prompt using the existing repository style as a starting point.
- Git global includes for default identity and GitHub-specific identity selected by remote URL.
- Finder hidden files visibility.

## Usage

```sh
git clone git@github.com:satandyh/.dotfiles.git ~/git/.dotfiles
cd ~/git/.dotfiles
./install.sh
```

The installer prints a plan first, asks for confirmation, applies only additive changes, and writes a report under `state/`.

## Safety

The installer does not delete existing app settings or old config files. If a target config already exists and differs, it writes a candidate file under `state/candidates/` and reports a manual merge step.

Cleanup is never automatic. If cleanup candidates appear, review the generated report and remove files yourself later.

## Manual Follow-up

After installation, sign in to Chrome, Google Drive, Yandex Disk, Claude, Codex, and KeePassXC as needed. VS Code extensions are not installed automatically; recommended manual installs are Codex, Anthropic/Claude, Google Cloud Code, and Project Manager.

Flameshot may require macOS Screen Recording or Accessibility permissions before it can capture the screen.
