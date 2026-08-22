#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$REPO_ROOT/state"
CANDIDATE_DIR="$STATE_DIR/candidates"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$STATE_DIR/report-$RUN_ID.md"
MANUAL_FILE="$STATE_DIR/manual-steps-$RUN_ID.txt"

DONE_COUNT=0
SKIP_COUNT=0
MANUAL_COUNT=0

log() {
  printf '%s\n' "$*"
}

done_item() {
  DONE_COUNT=$((DONE_COUNT + 1))
  log "OK: $*"
}

skip_item() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  log "SKIP: $*"
}

manual_item() {
  MANUAL_COUNT=$((MANUAL_COUNT + 1))
  log "MANUAL: $*"
  printf '%s\n' "$*" >> "$MANUAL_FILE"
}

require_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    log "This setup is intended for macOS only."
    exit 1
  fi

  if [ "$(uname -m)" != "arm64" ]; then
    log "This setup targets Apple Silicon Macs. Current architecture: $(uname -m)"
    exit 1
  fi
}

brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

preflight() {
  missing=0

  for path in \
    "$REPO_ROOT/Brewfile" \
    "$REPO_ROOT/config/ghostty/config" \
    "$REPO_ROOT/config/starship/starship.toml" \
    "$REPO_ROOT/config/tmux/tmux.conf" \
    "$REPO_ROOT/config/zsh/zshrc" \
    "$REPO_ROOT/config/git/.gitconfig" \
    "$REPO_ROOT/config/git/.gitconfig-default" \
    "$REPO_ROOT/config/git/.gitconfig-github"
  do
    if [ ! -r "$path" ]; then
      log "Missing required file: $path"
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    log "Preflight failed. No setup changes were applied."
    exit 1
  fi
}

print_plan() {
  log "Plan:"
  log "- Ensure Homebrew is installed."
  log "- Install or update packages from Brewfile."
  log "- Install Oh My Zsh, Zsh plugins, TPM, and tmux plugins."
  log "- Add managed zsh source block to ~/.zshrc."
  log "- Install Ghostty, Starship, and Git config files safely."
  log "- Enable hidden files in Finder."
  log "- Write a report under state/."
  log ""
  log "No cleanup or deletion will be performed."
  log ""
}

confirm() {
  printf 'Apply this setup? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) log "Canceled."; exit 0 ;;
  esac
}

init_state() {
  mkdir -p "$STATE_DIR" "$CANDIDATE_DIR"
  : > "$MANUAL_FILE"
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ]; then
    brew_shellenv
    skip_item "Homebrew already installed"
    return
  fi

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew_shellenv
  done_item "Homebrew installed"
}

install_brew_bundle() {
  brew bundle install --file "$REPO_ROOT/Brewfile" --no-upgrade
  done_item "Brewfile applied"
}

clone_repo_safely() {
  repo="$1"
  dest="$2"
  label="$3"

  if [ -d "$dest/.git" ]; then
    skip_item "$label already installed"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    manual_item "$label was not installed because $dest already exists and is not a Git checkout"
  else
    mkdir -p "$(dirname "$dest")"
    git clone --depth=1 "$repo" "$dest"
    done_item "$label installed at $dest"
  fi
}

install_terminal_dependencies() {
  clone_repo_safely "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh" "Oh My Zsh"
  clone_repo_safely "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
  clone_repo_safely "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  clone_repo_safely "https://github.com/zsh-users/zsh-completions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" "zsh-completions"
  clone_repo_safely "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm" "TPM"
}

install_tmux_plugins() {
  if ! cmp -s "$REPO_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf"; then
    manual_item "tmux plugins were not installed because ~/.tmux.conf does not match the managed config"
    return
  fi

  plugin_installer="$HOME/.tmux/plugins/tpm/bin/install_plugins"
  if [ ! -x "$plugin_installer" ]; then
    manual_item "tmux plugins were not installed because TPM is unavailable at $plugin_installer"
    return
  fi

  "$plugin_installer"
  done_item "tmux plugins installed"
}

safe_name_for_path() {
  printf '%s' "$1" | sed "s#^$HOME#HOME#; s#[/ ]#_#g"
}

install_file_safely() {
  src="$1"
  dest="$2"
  label="$3"

  mkdir -p "$(dirname "$dest")"
  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
    done_item "$label installed at $dest"
  elif cmp -s "$src" "$dest"; then
    skip_item "$label already up to date"
  else
    candidate="$CANDIDATE_DIR/$(safe_name_for_path "$dest")"
    cp "$src" "$candidate"
    manual_item "$label differs from existing $dest. Candidate written to $candidate"
  fi
}

ensure_managed_block() {
  dest="$1"
  label="$2"
  block="$3"
  marker="$4"

  mkdir -p "$(dirname "$dest")"
  touch "$dest"

  if grep -F "$marker" "$dest" >/dev/null 2>&1; then
    skip_item "$label already has managed block"
  else
    {
      printf '\n'
      printf '%s\n' "$block"
    } >> "$dest"
    done_item "$label managed block added"
  fi
}

configure_zsh() {
  install_file_safely "$REPO_ROOT/config/zsh/zshrc" "$HOME/.config/dotfiles/zsh/zshrc" "zsh config"

  block='# >>> dotfiles zsh
source "$HOME/.config/dotfiles/zsh/zshrc"
# <<< dotfiles zsh'
  ensure_managed_block "$HOME/.zshrc" "~/.zshrc" "$block" "# >>> dotfiles zsh"
}

configure_git() {
  install_file_safely "$REPO_ROOT/config/git/.gitconfig" "$HOME/.gitconfig" "global Git config"
  install_file_safely "$REPO_ROOT/config/git/.gitconfig-default" "$HOME/.gitconfig-default" "default Git identity"
  install_file_safely "$REPO_ROOT/config/git/.gitconfig-github" "$HOME/.gitconfig-github" "GitHub Git identity"
}

configure_files() {
  install_file_safely "$REPO_ROOT/config/ghostty/config" "$HOME/.config/ghostty/config" "Ghostty config"
  install_file_safely "$REPO_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml" "Starship config"
  install_file_safely "$REPO_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux config"
  configure_zsh
  configure_git
}

configure_finder() {
  current="$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || true)"
  if [ "$current" = "1" ] || [ "$current" = "true" ] || [ "$current" = "TRUE" ]; then
    skip_item "Finder already shows hidden files"
    return
  fi

  defaults write com.apple.finder AppleShowAllFiles -bool true
  killall Finder >/dev/null 2>&1 || true
  done_item "Finder hidden files enabled"
}

write_manual_steps() {
  manual_item "Sign in to Google Chrome."
  manual_item "Sign in to Google Drive and confirm sync folders."
  manual_item "Sign in to Yandex Disk and confirm sync folders."
  manual_item "Open KeePassXC and connect your database/browser integration."
  manual_item "Open Claude and sign in."
  manual_item "Run Codex login/setup if required by the installed Codex app or CLI."
  manual_item "Install VS Code extensions manually if needed: Codex, Anthropic/Claude, Google Cloud Code, Project Manager."
  manual_item "Grant Flameshot Screen Recording or Accessibility permission if macOS asks."
}

write_report() {
  {
    printf '# macOS Setup Report\n\n'
    printf -- '- Done: %s\n' "$DONE_COUNT"
    printf -- '- Skipped: %s\n' "$SKIP_COUNT"
    printf -- '- Manual steps: %s\n\n' "$MANUAL_COUNT"
    printf '## Manual Steps\n\n'
    sed 's/^/- /' "$MANUAL_FILE"
    printf '\n## Notes\n\n'
    printf -- '- Existing config files are never deleted.\n'
    printf -- '- Differing config candidates are written under `%s`.\n' "$CANDIDATE_DIR"
  } > "$REPORT_FILE"

  log ""
  log "Report written to $REPORT_FILE"
  log ""
  cat "$REPORT_FILE"
}

main() {
  require_macos
  preflight
  print_plan
  confirm
  init_state
  ensure_homebrew
  install_brew_bundle
  install_terminal_dependencies
  configure_files
  install_tmux_plugins
  configure_finder
  write_manual_steps
  write_report
}

main "$@"
