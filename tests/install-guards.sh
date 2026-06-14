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
    exit 0
    ;;
  *)
    exit 0
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

  chmod +x "$FAKE_BIN/uname" "$FAKE_BIN/brew" "$FAKE_BIN/defaults" "$FAKE_BIN/killall"

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
test -z "$(find "$RUN_DIR/state" -name 'report-*.md' -type f -print -quit)" || fail "cancel should not write report"

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

prepare_case "conflict" "Darwin" "arm64"
mkdir -p "$FAKE_HOME/.config/ghostty"
printf 'local ghostty setting\n' > "$FAKE_HOME/.config/ghostty/config"
printf '# local zshrc\n' > "$FAKE_HOME/.zshrc"

output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"
assert_contains "$output" "Ghostty config differs from existing"
test "$(cat "$FAKE_HOME/.config/ghostty/config")" = "local ghostty setting" || fail "existing config should be left untouched"
test -f "$RUN_DIR/state/candidates/HOME_.config_ghostty_config" || fail "conflicting config should write a candidate"
cmp -s "$RUN_DIR/config/ghostty/config" "$RUN_DIR/state/candidates/HOME_.config_ghostty_config" || fail "candidate should match repository config"
grep -F "# >>> dotfiles zsh" "$FAKE_HOME/.zshrc" >/dev/null || fail "managed zsh block should be added"

output="$(cd "$RUN_DIR" && printf 'y\n' | ./install.sh)"
assert_contains "$output" "~/.zshrc already has managed block"
marker_count="$(grep -F -c "# >>> dotfiles zsh" "$FAKE_HOME/.zshrc")"
test "$marker_count" -eq 1 || fail "managed zsh block should not be duplicated"

printf 'install guard tests passed\n'
