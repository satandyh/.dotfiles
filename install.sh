#!/usr/bin/env bash
set -eEuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$REPO_ROOT/state"
CANDIDATE_DIR="$STATE_DIR/candidates"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$STATE_DIR/report-$RUN_ID.md"
MANUAL_FILE="$STATE_DIR/manual-steps-$RUN_ID.txt"
LANG_SWITCHER_APP_ID="1597566195"
APPLICATIONS_DIR="${APPLICATIONS_DIR:-/Applications}"
USER_APPLICATIONS_DIR="${USER_APPLICATIONS_DIR:-$HOME/Applications}"

DONE_COUNT=0
SKIP_COUNT=0
MANUAL_COUNT=0
RUN_STATUS="Completed"

SELECT_CORE=0
SELECT_TERMINAL=0
SELECT_OTHER=0
DO_INSTALL=0
DO_CONFIG=0
GROUP_ARGUMENT_SEEN=0
ACTION_ARGUMENT_SEEN=0
SELECTED_GROUPS=""
SELECTED_ACTIONS=""

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

usage() {
  cat <<'EOF'
Usage: ./install.sh [core] [terminal] [other] [install] [config]

Groups and actions can be combined in any order:
  ./install.sh core install
  ./install.sh terminal config
  ./install.sh core terminal install config

With no group, all groups are selected. With no action, both install and config run.
EOF
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      core) SELECT_CORE=1; GROUP_ARGUMENT_SEEN=1 ;;
      terminal) SELECT_TERMINAL=1; GROUP_ARGUMENT_SEEN=1 ;;
      other) SELECT_OTHER=1; GROUP_ARGUMENT_SEEN=1 ;;
      install) DO_INSTALL=1; ACTION_ARGUMENT_SEEN=1 ;;
      config) DO_CONFIG=1; ACTION_ARGUMENT_SEEN=1 ;;
      -h|--help) usage; exit 0 ;;
      *)
        log "Unknown argument: $arg"
        usage
        exit 2
        ;;
    esac
  done

  if [ "$GROUP_ARGUMENT_SEEN" -eq 0 ]; then
    SELECT_CORE=1
    SELECT_TERMINAL=1
    SELECT_OTHER=1
  fi

  if [ "$ACTION_ARGUMENT_SEEN" -eq 0 ]; then
    DO_INSTALL=1
    DO_CONFIG=1
  fi

  selected=""
  [ "$SELECT_CORE" -eq 0 ] || selected="$selected core"
  [ "$SELECT_TERMINAL" -eq 0 ] || selected="$selected terminal"
  [ "$SELECT_OTHER" -eq 0 ] || selected="$selected other"
  SELECTED_GROUPS="${selected# }"

  selected=""
  [ "$DO_INSTALL" -eq 0 ] || selected="$selected install"
  [ "$DO_CONFIG" -eq 0 ] || selected="$selected config"
  SELECTED_ACTIONS="${selected# }"
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

  required_files=""
  if [ "$DO_INSTALL" -eq 1 ]; then
    [ "$SELECT_CORE" -eq 0 ] || required_files="$required_files
$REPO_ROOT/Brewfile.core"
    [ "$SELECT_TERMINAL" -eq 0 ] || required_files="$required_files
$REPO_ROOT/Brewfile.terminal"
    [ "$SELECT_OTHER" -eq 0 ] || required_files="$required_files
$REPO_ROOT/Brewfile.other"
  fi
  if [ "$DO_CONFIG" -eq 1 ] && [ "$SELECT_TERMINAL" -eq 1 ]; then
    required_files="$required_files
$REPO_ROOT/config/ghostty/config
$REPO_ROOT/config/starship/starship.toml
$REPO_ROOT/config/tmux/tmux.conf
$REPO_ROOT/config/zsh/zshrc
$REPO_ROOT/config/zsh/zshrc-loader"
  fi
  if [ "$DO_CONFIG" -eq 1 ] && [ "$SELECT_CORE" -eq 1 ]; then
    required_files="$required_files
$REPO_ROOT/config/git/.gitconfig
$REPO_ROOT/config/git/.gitconfig-default
$REPO_ROOT/config/git/.gitconfig-github"
  fi

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ ! -r "$path" ]; then
      log "Missing required file: $path"
      missing=1
    fi
  done <<EOF
$required_files
EOF

  if [ "$missing" -ne 0 ]; then
    log "Preflight failed. No setup changes were applied."
    exit 1
  fi
}

print_plan() {
  log "Plan for groups: $SELECTED_GROUPS"
  if [ "$DO_INSTALL" -eq 1 ]; then
    log "- Install selected programs without upgrading existing ones."
  fi
  if [ "$DO_CONFIG" -eq 1 ]; then
    log "- Configure selected groups without overwriting differing files."
  fi
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
  if [ "$SELECT_CORE" -eq 1 ]; then
    DOTFILES_GROUP="core" brew bundle install --file "$REPO_ROOT/Brewfile.core" --no-upgrade
    done_item "core packages installed"
  fi
  if [ "$SELECT_TERMINAL" -eq 1 ]; then
    DOTFILES_GROUP="terminal" brew bundle install --file "$REPO_ROOT/Brewfile.terminal" --no-upgrade
    done_item "terminal packages installed"
  fi
  if [ "$SELECT_OTHER" -eq 1 ]; then
    DOTFILES_GROUP="other" brew bundle install --file "$REPO_ROOT/Brewfile.other" --no-upgrade
    done_item "other packages installed"
  fi
}

application_exists() {
  app_name="$1"
  [ -d "$APPLICATIONS_DIR/$app_name" ] || [ -d "$USER_APPLICATIONS_DIR/$app_name" ]
}

install_optional_cask() {
  token="$1"
  label="$2"
  app_name="$3"

  if brew list --cask "$token" >/dev/null 2>&1 || application_exists "$app_name"; then
    skip_item "$label already installed"
    return
  fi

  if brew install --cask "$token"; then
    done_item "$label installed from its official upstream release through Homebrew"
  else
    manual_item "$label was not installed automatically. Download it from the official project site and complete macOS security checks manually."
  fi
}

install_app_store_apps() {
  if application_exists "Lang Switcher.app"; then
    skip_item "Lang Switcher already installed"
    return
  fi

  if ! command -v mas >/dev/null 2>&1; then
    manual_item "Install Lang Switcher from the Mac App Store; the mas command is unavailable."
    return
  fi

  if mas list 2>/dev/null | grep -q "^$LANG_SWITCHER_APP_ID "; then
    skip_item "Lang Switcher already installed"
    return
  fi

  if mas install "$LANG_SWITCHER_APP_ID"; then
    done_item "Lang Switcher installed from the Mac App Store"
  else
    manual_item "Sign in to the Mac App Store, then install Lang Switcher (app ID $LANG_SWITCHER_APP_ID)."
  fi
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
  clone_repo_safely "https://github.com/tmux-plugins/tmux-sensible.git" "$HOME/.tmux/plugins/tmux-sensible" "tmux-sensible"
  clone_repo_safely "https://github.com/tmux-plugins/tmux-resurrect.git" "$HOME/.tmux/plugins/tmux-resurrect" "tmux-resurrect"
  clone_repo_safely "https://github.com/tmux-plugins/tmux-yank.git" "$HOME/.tmux/plugins/tmux-yank" "tmux-yank"
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

configure_zsh() {
  if [ ! -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    manual_item "zsh config was not installed because Oh My Zsh is incomplete at $HOME/.oh-my-zsh"
    return
  fi

  install_file_safely "$REPO_ROOT/config/zsh/zshrc" "$HOME/.config/dotfiles/zsh/zshrc" "zsh config"
  install_file_safely "$REPO_ROOT/config/zsh/zshrc-loader" "$HOME/.zshrc" "zsh loader"
}

configure_git() {
  install_file_safely "$REPO_ROOT/config/git/.gitconfig" "$HOME/.gitconfig" "global Git config"
  install_file_safely "$REPO_ROOT/config/git/.gitconfig-default" "$HOME/.gitconfig-default" "default Git identity"
  install_file_safely "$REPO_ROOT/config/git/.gitconfig-github" "$HOME/.gitconfig-github" "GitHub Git identity"
}

configure_terminal() {
  install_file_safely "$REPO_ROOT/config/ghostty/config" "$HOME/.config/ghostty/config" "Ghostty config"
  install_file_safely "$REPO_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml" "Starship config"
  install_file_safely "$REPO_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux config"
  configure_zsh
}

configure_core() {
  configure_git
  configure_finder
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

configure_other() {
  manual_item "Sign in to Google Chrome."
  manual_item "Sign in to Google Drive and confirm sync folders."
  manual_item "Sign in to Yandex Disk and confirm sync folders."
  manual_item "Open KeePassXC and connect your database/browser integration."
  manual_item "Open Claude and sign in."
  manual_item "Open ChatGPT and sign in."
  manual_item "Install VS Code extensions manually if needed: Codex, Anthropic/Claude, Google Cloud Code, Project Manager."
  manual_item "Grant Flameshot Screen Recording or Accessibility permission if macOS asks."
}

CONFIG_DEPENDENCY_ERRORS=0
MISSING_CORE_DEPENDENCY=0
MISSING_TERMINAL_DEPENDENCY=0
MISSING_OTHER_DEPENDENCY=0

missing_config_dependency() {
  group="$1"
  description="$2"

  manual_item "$description is required before configuring the $group group."
  CONFIG_DEPENDENCY_ERRORS=1
  case "$group" in
    core) MISSING_CORE_DEPENDENCY=1 ;;
    terminal) MISSING_TERMINAL_DEPENDENCY=1 ;;
    other) MISSING_OTHER_DEPENDENCY=1 ;;
  esac
}

require_config_command() {
  group="$1"
  command_name="$2"
  label="$3"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing_config_dependency "$group" "$label"
  fi
}

require_config_path() {
  group="$1"
  path="$2"
  label="$3"

  if [ ! -e "$path" ]; then
    missing_config_dependency "$group" "$label"
  fi
}

require_config_app() {
  group="$1"
  app_name="$2"
  label="$3"

  if ! application_exists "$app_name"; then
    missing_config_dependency "$group" "$label"
  fi
}

fira_code_installed() {
  for font_path in "$HOME"/Library/Fonts/FiraCode* /Library/Fonts/FiraCode*; do
    if [ -e "$font_path" ]; then
      return 0
    fi
  done
  return 1
}

validate_config_dependencies() {
  CONFIG_DEPENDENCY_ERRORS=0
  MISSING_CORE_DEPENDENCY=0
  MISSING_TERMINAL_DEPENDENCY=0
  MISSING_OTHER_DEPENDENCY=0

  if [ "$SELECT_CORE" -eq 1 ]; then
    require_config_command "core" "git" "Git"
  fi

  if [ "$SELECT_TERMINAL" -eq 1 ]; then
    require_config_command "terminal" "git" "Git"
    require_config_command "terminal" "tmux" "tmux"
    require_config_command "terminal" "starship" "Starship"
    require_config_command "terminal" "fzf" "fzf"
    require_config_app "terminal" "Ghostty.app" "Ghostty"
    if ! fira_code_installed; then
      missing_config_dependency "terminal" "Fira Code"
    fi
    require_config_path "terminal" "$HOME/.oh-my-zsh/oh-my-zsh.sh" "Oh My Zsh"
    require_config_path "terminal" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    require_config_path "terminal" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
    require_config_path "terminal" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" "zsh-completions"
    require_config_path "terminal" "$HOME/.tmux/plugins/tpm" "TPM"
    require_config_path "terminal" "$HOME/.tmux/plugins/tmux-sensible" "tmux-sensible"
    require_config_path "terminal" "$HOME/.tmux/plugins/tmux-resurrect" "tmux-resurrect"
    require_config_path "terminal" "$HOME/.tmux/plugins/tmux-yank" "tmux-yank"
  fi

  if [ "$SELECT_OTHER" -eq 1 ]; then
    require_config_app "other" "Visual Studio Code.app" "Visual Studio Code"
    require_config_app "other" "Google Chrome.app" "Google Chrome"
    require_config_app "other" "Google Drive.app" "Google Drive"
    require_config_app "other" "Yandex.Disk.app" "Yandex Disk"
    require_config_app "other" "KeePassXC.app" "KeePassXC"
    require_config_app "other" "MacWhisper.app" "MacWhisper"
    require_config_app "other" "Claude.app" "Claude"
    require_config_app "other" "ChatGPT.app" "ChatGPT"
    require_config_app "other" "UTM.app" "UTM"
    require_config_app "other" "Lang Switcher.app" "Lang Switcher"
  fi

  if [ "$CONFIG_DEPENDENCY_ERRORS" -eq 0 ]; then
    return 0
  fi

  log ""
  log "Configuration prerequisites are missing. No config files were changed."
  [ "$MISSING_CORE_DEPENDENCY" -eq 0 ] || log "Run: ./install.sh core install"
  [ "$MISSING_TERMINAL_DEPENDENCY" -eq 0 ] || log "Run: ./install.sh terminal install"
  [ "$MISSING_OTHER_DEPENDENCY" -eq 0 ] || log "Run: ./install.sh other install"
  return 1
}

write_report() {
  {
    printf '# macOS Setup Report\n\n'
    printf -- '- Status: %s\n' "$RUN_STATUS"
    printf -- '- Groups: %s\n' "$SELECTED_GROUPS"
    printf -- '- Actions: %s\n' "$SELECTED_ACTIONS"
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

handle_error() {
  status="$1"
  line="$2"
  command="$3"

  trap - ERR
  RUN_STATUS="Failed"
  manual_item "Setup stopped at line $line while running: $command"
  write_report
  exit "$status"
}

main() {
  parse_args "$@"
  require_macos
  preflight
  print_plan
  confirm
  init_state
  trap 'handle_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
  if [ "$DO_INSTALL" -eq 1 ]; then
    ensure_homebrew
    install_brew_bundle
    if [ "$SELECT_TERMINAL" -eq 1 ]; then
      install_terminal_dependencies
    fi
    if [ "$SELECT_OTHER" -eq 1 ]; then
      install_app_store_apps
      install_optional_cask "flameshot" "Flameshot" "Flameshot.app"
    fi
  fi
  if [ "$DO_CONFIG" -eq 1 ]; then
    if ! validate_config_dependencies; then
      RUN_STATUS="Failed"
      write_report
      exit 1
    fi
    [ "$SELECT_CORE" -eq 0 ] || configure_core
    [ "$SELECT_TERMINAL" -eq 0 ] || configure_terminal
    [ "$SELECT_OTHER" -eq 0 ] || configure_other
  fi
  write_report
  trap - ERR
}

main "$@"
