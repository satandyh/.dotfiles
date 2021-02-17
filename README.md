# This repo in for install environment to Fedora (or other rpm based distros)

## Requrements

For successful installation it need:

- installed git
- wheel group for your user

## Installation

```sh
git clone git@github.com:satandyh/.dotfiles.git ~/.dotfiles
```

## Usage

```sh
~/.dotfiles/bin/dot-bootstrap.sh
```

## Common

It consists from several ansible roles. Each of role installs and configures program or do config for OS.

For this moment it has:

- common:
  - add repos
    - fira fonts
  - tuning some parameters
    - fonts
    - tuned
    - lynis
    - rkhunter
  - OS configs
- alacritty (terminal emulator)
- vim
- tmux
- zsh
- git
- VS Code

# shell

Use zsh with oh-my-zsh  
plugins=(git docker tmux zsh-autosuggestions zsh-syntax-highlighting command-time)  
maybe add fzf?

* * *

# VundleVim and .vimrc

1. install vundle from this repo [VundleVim](https://github.com/VundleVim/Vundle.vim)
2. copy .vimrc file to `~/.vimrc`
3. run `:PluginInstall` inside vim
4. do the same for all users

# TODO

- Add flameshot
