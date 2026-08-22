# macOS Terminal Setup

This repository installs and configures a reproducible terminal environment for Apple Silicon Macs. After cloning the repository, one installer command sets up the required programs, fonts, plugins, and managed configuration files.

## What It Installs

- Homebrew if missing.
- CLI tools: `git`, `curl`, `htop`, `mas`, `tmux`, `starship`, and `fzf`.
- Apps and fonts through Homebrew Cask using official upstream artifacts: Ghostty, VS Code, Chrome, Google Drive, Yandex Disk, KeePassXC, MacWhisper, Raycast, Claude, ChatGPT, UTM, Flameshot, and Fira Code.
- Lang Switcher through the Mac App Store, using `mas` when the current Apple ID session permits it.
- Oh My Zsh and the autosuggestions, syntax-highlighting, and completions plugins.
- TPM and the tmux sensible, resurrect, and yank plugins.

## What It Configures

- Zsh with Oh My Zsh, completions, autosuggestions, syntax highlighting, fzf integration, and Starship prompt.
- Ghostty with Fira Code, Apple System Colors, and light transparency.
- tmux mouse and copy-mode behavior plus TPM-managed sensible, resurrect, and yank plugins.
- Starship prompt using the existing repository style as a starting point.
- Git global includes for default identity and GitHub-specific identity selected by remote URL.
- Finder hidden files visibility.

## Usage

```sh
git clone git@github.com:satandyh/.dotfiles.git ~/git/.dotfiles
cd ~/git/.dotfiles && ./install.sh
```

After the repository is downloaded, `./install.sh` is the single command that deploys the terminal. It prints a plan, asks for confirmation, installs dependencies in order, and writes a report under `state/`.

Homebrew installs only missing Brewfile dependencies. Programs that are already present are kept as installed and are not upgraded automatically. Apps already found in `/Applications` or `~/Applications` are not adopted or reinstalled.

## Installation Channels

Each program uses a repeatable form of its preferred macOS distribution channel:

| Channel | Programs |
| --- | --- |
| Homebrew formula | Homebrew, Git, curl, htop, mas, tmux, Starship, fzf |
| Homebrew Cask fetching the vendor's official artifact | Fira Code, Ghostty, VS Code, Chrome, Google Drive, Yandex Disk, KeePassXC, MacWhisper, Raycast, Claude, ChatGPT, UTM |
| Mac App Store through `mas` | Lang Switcher |
| Isolated Homebrew Cask attempt with manual fallback | Flameshot |
| Official Git repository | Oh My Zsh, its Zsh plugins, TPM |

Flameshot is kept outside the main bundle because its Homebrew cask currently has a macOS Gatekeeper compatibility issue. A Flameshot failure is reported as a manual step and does not stop the rest of the setup. The installer never disables Gatekeeper or removes quarantine attributes.

ChatGPT and Claude are installed only as desktop applications. Their command-line tools are not part of this setup.

Raycast, Lang Switcher, MacWhisper, UTM, and the other non-terminal apps are install-only in this iteration. Raycast settings and data export will be handled separately using Raycast's encrypted `.rayconfig` format.

## Safety

The installer does not delete existing app settings or old config files. If a target config already exists and differs, it writes a candidate file under `state/candidates/` and reports a manual merge step.

Existing Oh My Zsh, Zsh plugin, TPM, and tmux plugin directories are reused and never replaced by the installer.

Cleanup is never automatic. If cleanup candidates appear, review the generated report and remove files yourself later.

## Manual Follow-up

After installation, sign in to Chrome, Google Drive, Yandex Disk, Claude, ChatGPT, and KeePassXC as needed. VS Code extensions are not installed automatically; recommended manual installs are Codex, Anthropic/Claude, Google Cloud Code, and Project Manager.

Flameshot may require macOS Screen Recording or Accessibility permissions before it can capture the screen.
