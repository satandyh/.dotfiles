#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install-smoke.XXXXXX")"
FAKE_BIN="$WORK_DIR/bin"
FAKE_HOME="$WORK_DIR/home"
RUN_DIR="$WORK_DIR/repo"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$FAKE_HOME" "$RUN_DIR"

cp -R "$REPO_ROOT"/. "$RUN_DIR"
rm -rf "$RUN_DIR/.git" "$RUN_DIR/state"

cat > "$FAKE_BIN/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -s) printf 'Darwin\n' ;;
  -m) printf 'arm64\n' ;;
  *) /usr/bin/uname "$@" ;;
esac
EOF

cat > "$FAKE_BIN/brew" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  shellenv)
    printf 'export HOMEBREW_PREFIX="%s"\n' "$FAKE_BREW_PREFIX"
    ;;
  --prefix)
    printf '%s\n' "$FAKE_BREW_PREFIX"
    ;;
  bundle)
    printf '%s\n' "$*" > "$HOME/.brew-bundle-args"
    : > "$HOME/.brew-bundle-ran"
    exit 0
    ;;
  list)
    if [ "${2:-}" = "--cask" ] && [ "${3:-}" = "flameshot" ] && [ -f "$HOME/.flameshot-installed" ]; then
      exit 0
    fi
    exit 1
    ;;
  install)
    test "${2:-}" = "--cask"
    test "${3:-}" = "flameshot"
    : > "$HOME/.flameshot-installed"
    ;;
  *)
    exit 0
    ;;
esac
EOF

cat > "$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" != "clone" ]; then
  exit 0
fi

test -f "$HOME/.brew-bundle-ran"

for arg in "$@"; do
  destination="$arg"
done

mkdir -p "$destination/.git"
case "$destination" in
  */tpm)
    mkdir -p "$destination/bin"
    cat > "$destination/bin/install_plugins" <<'SCRIPT'
#!/usr/bin/env bash
test -f "$HOME/.tmux.conf"
mkdir -p "$HOME/.tmux/plugins"
: > "$HOME/.tmux/plugins/.install-plugins-ran"
SCRIPT
    chmod +x "$destination/bin/install_plugins"
    ;;
esac
EOF

cat > "$FAKE_BIN/mas" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  list)
    if [ -f "$HOME/.lang-switcher-installed" ]; then
      printf '1597566195 Smart Language Switcher\n'
    fi
    ;;
  install)
    test "${2:-}" = "1597566195"
    : > "$HOME/.lang-switcher-installed"
    ;;
esac
EOF

cat > "$FAKE_BIN/defaults" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "read" ]; then
  printf 'true\n'
fi
exit 0
EOF

cat > "$FAKE_BIN/killall" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$FAKE_BIN/uname" "$FAKE_BIN/brew" "$FAKE_BIN/git" "$FAKE_BIN/mas" "$FAKE_BIN/defaults" "$FAKE_BIN/killall"

export HOME="$FAKE_HOME"
export FAKE_BREW_PREFIX="$WORK_DIR/homebrew"
export APPLICATIONS_DIR="$WORK_DIR/Applications"
export USER_APPLICATIONS_DIR="$FAKE_HOME/Applications"
export PATH="$FAKE_BIN:/usr/bin:/bin:/usr/sbin:/sbin"

mkdir -p "$FAKE_BREW_PREFIX/share/zsh-autosuggestions" \
  "$FAKE_BREW_PREFIX/share/zsh-syntax-highlighting" \
  "$FAKE_BREW_PREFIX/share/zsh-completions"

output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"

report="$(find "$RUN_DIR/state" -name 'report-*.md' -type f | head -n 1)"
manual_steps="$(find "$RUN_DIR/state" -name 'manual-steps-*.txt' -type f | head -n 1)"

test -n "$report"
test -n "$manual_steps"
grep -F -- '- Done:' "$report" >/dev/null
grep -F -- '- Skipped:' "$report" >/dev/null
grep -F -- '- Manual steps:' "$report" >/dev/null
grep -F '## Manual Steps' "$report" >/dev/null
grep -F 'Report written to' <<< "$output" >/dev/null
grep -F '# macOS Setup Report' <<< "$output" >/dev/null
grep -F -- '- Done:' <<< "$output" >/dev/null
grep -F '## Manual Steps' <<< "$output" >/dev/null
test -f "$FAKE_HOME/.config/ghostty/config"
test -f "$FAKE_HOME/.tmux.conf"
test -f "$FAKE_HOME/.config/starship.toml"
test -f "$FAKE_HOME/.config/dotfiles/zsh/zshrc"
test -f "$FAKE_HOME/.gitconfig"
test -f "$FAKE_HOME/.gitconfig-default"
test -f "$FAKE_HOME/.gitconfig-github"
test -d "$FAKE_HOME/.oh-my-zsh/.git"
test -d "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/.git"
test -d "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/.git"
test -d "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-completions/.git"
test -d "$FAKE_HOME/.tmux/plugins/tpm/.git"
test -f "$FAKE_HOME/.tmux/plugins/.install-plugins-ran"
test -f "$FAKE_HOME/.lang-switcher-installed"
test -f "$FAKE_HOME/.flameshot-installed"
grep -F -- '--no-upgrade' "$FAKE_HOME/.brew-bundle-args" >/dev/null
grep -F 'brew "fzf"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'brew "starship"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'brew "tmux"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'brew "mas"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "ghostty"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "font-fira-code"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "raycast"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "macwhisper"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "utm"' "$RUN_DIR/Brewfile" >/dev/null
grep -F 'cask "chatgpt"' "$RUN_DIR/Brewfile" >/dev/null
if grep -F 'cask "codex"' "$RUN_DIR/Brewfile" >/dev/null; then
  printf 'The Codex CLI must not be installed\n' >&2
  exit 1
fi
if grep -F 'cask "flameshot"' "$RUN_DIR/Brewfile" >/dev/null; then
  printf 'Flameshot must not be able to fail the main Brew bundle\n' >&2
  exit 1
fi
grep -F 'mas install "$LANG_SWITCHER_APP_ID"' "$RUN_DIR/install.sh" >/dev/null
grep -F 'install_optional_cask "flameshot"' "$RUN_DIR/install.sh" >/dev/null

second_output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"
grep -F 'Oh My Zsh already installed' <<< "$second_output" >/dev/null
grep -F 'TPM already installed' <<< "$second_output" >/dev/null
grep -F 'Lang Switcher already installed' <<< "$second_output" >/dev/null
grep -F 'Flameshot already installed' <<< "$second_output" >/dev/null
marker_count="$(grep -F -c "# >>> dotfiles zsh" "$FAKE_HOME/.zshrc")"
test "$marker_count" -eq 1

printf 'install smoke test passed\n'
