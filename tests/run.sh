#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$REPO_ROOT/tests/install-smoke.sh"
"$REPO_ROOT/tests/install-guards.sh"

printf 'all tests passed\n'
