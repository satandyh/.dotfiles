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
export FAKE_BREW_PREFIX="$WORK_DIR/homebrew"
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
test -f "$FAKE_HOME/.config/ghostty/config"
test -f "$FAKE_HOME/.config/starship.toml"
test -f "$FAKE_HOME/.config/dotfiles/zsh/zshrc"
test -f "$FAKE_HOME/.gitconfig"
test -f "$FAKE_HOME/.gitconfig-default"
test -f "$FAKE_HOME/.gitconfig-github"

printf 'install smoke test passed\n'
