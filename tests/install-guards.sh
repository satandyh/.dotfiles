#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install-guards.XXXXXX")"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  haystack="$1"
  needle="$2"
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "expected output to contain: $needle" ;;
  esac
}

prepare_case() {
  name="$1"
  uname_s="$2"
  uname_m="$3"

  CASE_DIR="$WORK_DIR/$name"
  FAKE_BIN="$CASE_DIR/bin"
  FAKE_HOME="$CASE_DIR/home"
  RUN_DIR="$CASE_DIR/repo"

  mkdir -p "$FAKE_BIN" "$FAKE_HOME" "$RUN_DIR"
  cp -R "$REPO_ROOT"/. "$RUN_DIR"
  rm -rf "$RUN_DIR/.git" "$RUN_DIR/state"

  cat > "$FAKE_BIN/uname" <<EOF
#!/usr/bin/env bash
case "\${1:-}" in
  -s) printf '%s\n' "$uname_s" ;;
  -m) printf '%s\n' "$uname_m" ;;
  *) /usr/bin/uname "\$@" ;;
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
  export FAKE_BREW_PREFIX="$CASE_DIR/homebrew"
  export PATH="$FAKE_BIN:/usr/bin:/bin:/usr/sbin:/sbin"

  mkdir -p "$FAKE_BREW_PREFIX/share/zsh-autosuggestions" \
    "$FAKE_BREW_PREFIX/share/zsh-syntax-highlighting" \
    "$FAKE_BREW_PREFIX/share/zsh-completions"
}

prepare_case "cancel" "Darwin" "arm64"
output="$(cd "$RUN_DIR" && printf 'n\n' | ./install.sh)"
assert_contains "$output" "Canceled."
test ! -f "$FAKE_HOME/.config/ghostty/config" || fail "cancel should not install config files"
test ! -d "$RUN_DIR/state" || fail "cancel should not initialize state files"

prepare_case "linux" "Linux" "arm64"
set +e
output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh 2>&1)"
status="$?"
set -e
test "$status" -ne 0 || fail "Linux should be rejected"
assert_contains "$output" "intended for macOS only"
test ! -f "$FAKE_HOME/.config/ghostty/config" || fail "Linux guard should stop before config writes"

prepare_case "intel" "Darwin" "x86_64"
set +e
output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh 2>&1)"
status="$?"
set -e
test "$status" -ne 0 || fail "Intel Macs should be rejected"
assert_contains "$output" "targets Apple Silicon Macs"
test ! -f "$FAKE_HOME/.config/ghostty/config" || fail "architecture guard should stop before config writes"

prepare_case "missing-source" "Darwin" "arm64"
rm "$RUN_DIR/config/git/.gitconfig-github"
set +e
output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh 2>&1)"
status="$?"
set -e
test "$status" -ne 0 || fail "missing source file should fail preflight"
assert_contains "$output" "Missing required file:"
assert_contains "$output" "Preflight failed. No setup changes were applied."
test ! -f "$FAKE_HOME/.config/ghostty/config" || fail "preflight should stop before config writes"
test ! -d "$RUN_DIR/state" || fail "preflight should stop before state files are initialized"

prepare_case "conflict" "Darwin" "arm64"
mkdir -p "$FAKE_HOME/.config/ghostty"
mkdir -p "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
printf 'local ghostty setting\n' > "$FAKE_HOME/.config/ghostty/config"
printf 'local tmux setting\n' > "$FAKE_HOME/.tmux.conf"
printf 'local plugin setting\n' > "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/local-setting"
printf '# local zshrc\n' > "$FAKE_HOME/.zshrc"

output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"
assert_contains "$output" "Ghostty config differs from existing"
test "$(cat "$FAKE_HOME/.config/ghostty/config")" = "local ghostty setting" || fail "existing config should be left untouched"
test -f "$RUN_DIR/state/candidates/HOME_.config_ghostty_config" || fail "conflicting config should write a candidate"
cmp -s "$RUN_DIR/config/ghostty/config" "$RUN_DIR/state/candidates/HOME_.config_ghostty_config" || fail "candidate should match repository config"
assert_contains "$output" "tmux config differs from existing"
test "$(cat "$FAKE_HOME/.tmux.conf")" = "local tmux setting" || fail "existing tmux config should be left untouched"
test -f "$RUN_DIR/state/candidates/HOME_.tmux.conf" || fail "conflicting tmux config should write a candidate"
cmp -s "$RUN_DIR/config/tmux/tmux.conf" "$RUN_DIR/state/candidates/HOME_.tmux.conf" || fail "tmux candidate should match repository config"
test "$(cat "$FAKE_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/local-setting")" = "local plugin setting" || fail "existing plugin directory should be left untouched"
test ! -f "$FAKE_HOME/.tmux/plugins/.install-plugins-ran" || fail "tmux plugins should not be installed for a conflicting tmux config"
grep -F "# >>> dotfiles zsh" "$FAKE_HOME/.zshrc" >/dev/null || fail "managed zsh block should be added"

output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"
assert_contains "$output" "~/.zshrc already has managed block"
marker_count="$(grep -F -c "# >>> dotfiles zsh" "$FAKE_HOME/.zshrc")"
test "$marker_count" -eq 1 || fail "managed zsh block should not be duplicated"

printf 'install guard tests passed\n'
