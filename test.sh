#!/bin/bash
# test.sh — Run tests across all sub-packages.
# Usage:
#   ./test.sh              # run every package that has a test/ directory
#   ./test.sh --coverage   # also collect lcov coverage
#   ./test.sh packages/grid_core packages/grid_ui   # specific packages only

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────

FLUTTER="${FLUTTER_BIN:-/Users/loic/fvm/versions/3.41.6/bin/flutter}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COVERAGE=false

# ── Colour helpers ─────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $*"; }
fail() { echo -e "${RED}✗${RESET} $*"; }
info() { echo -e "${CYAN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $*"; }
banner() { echo -e "\n${BOLD}${CYAN}$*${RESET}"; }

# ── Argument parsing ───────────────────────────────────────────────────────────

EXPLICIT_PACKAGES=()
for arg in "$@"; do
  case "$arg" in
    --coverage) COVERAGE=true ;;
    --help|-h)
      echo "Usage: ./test.sh [--coverage] [package/path ...]"
      echo ""
      echo "  --coverage   Collect lcov coverage into each package's coverage/ dir"
      echo "  package/path Run only the listed packages (default: all with test/)"
      exit 0
      ;;
    *) EXPLICIT_PACKAGES+=("$arg") ;;
  esac
done

# ── Discover packages ──────────────────────────────────────────────────────────

cd "$REPO_ROOT"

if [ ${#EXPLICIT_PACKAGES[@]} -gt 0 ]; then
  PACKAGES=("${EXPLICIT_PACKAGES[@]}")
else
  # Auto-discover: any sub-package that contains a test/ directory.
  PACKAGES=()
  while IFS= read -r dir; do
    PACKAGES+=("$dir")
  done < <(
    find packages -maxdepth 2 -name "pubspec.yaml" -not -path "*/.*" \
      | sed 's|/pubspec.yaml||' \
      | while read -r pkg; do
          [ -d "$pkg/test" ] && echo "$pkg"
        done \
      | sort
  )
fi

if [ ${#PACKAGES[@]} -eq 0 ]; then
  warn "No packages with a test/ directory found."
  exit 0
fi

# ── Verify Flutter binary ──────────────────────────────────────────────────────

if [ ! -x "$FLUTTER" ]; then
  fail "Flutter binary not found: $FLUTTER"
  echo "  Set FLUTTER_BIN env var to point to the correct flutter binary."
  exit 1
fi

FLUTTER_VERSION=$("$FLUTTER" --version 2>/dev/null | head -1)
info "Using $FLUTTER_VERSION"

# ── Run tests ─────────────────────────────────────────────────────────────────

PASS_PKGS=()
FAIL_PKGS=()
TOTAL_TESTS=0

for PKG in "${PACKAGES[@]}"; do
  PKG_ABS="$REPO_ROOT/$PKG"
  PKG_NAME=$(basename "$PKG")

  banner "────────────────────────────────────────"
  info "Testing ${BOLD}$PKG${RESET}"

  TEST_ARGS=("test")
  if [ "$COVERAGE" = true ]; then
    TEST_ARGS+=("--coverage")
  fi

  # Capture output so we can parse the test count from the summary line.
  TMPOUT=$(mktemp)
  set +e
  (cd "$PKG_ABS" && "$FLUTTER" "${TEST_ARGS[@]}") 2>&1 | tee "$TMPOUT"
  EXIT_CODE=${PIPESTATUS[0]}
  set -e

  # Parse total count from the final "+N:" summary line.
  COUNT=$(grep -oE '^\d{2}:\d{2} \+([0-9]+):' "$TMPOUT" | tail -1 | grep -oE '\+[0-9]+' | tr -d '+' || true)
  rm -f "$TMPOUT"

  if [ "$EXIT_CODE" -eq 0 ]; then
    PASS_PKGS+=("$PKG_NAME")
    TOTAL_TESTS=$((TOTAL_TESTS + ${COUNT:-0}))
    ok "${BOLD}$PKG_NAME${RESET} passed (${COUNT:-?} tests)"
  else
    FAIL_PKGS+=("$PKG_NAME")
    fail "${BOLD}$PKG_NAME${RESET} FAILED"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────

banner "════════════════════════════════════════"
echo -e "${BOLD}Results${RESET}"
echo ""

for p in "${PASS_PKGS[@]+"${PASS_PKGS[@]}"}"; do
  ok "$p"
done
for p in "${FAIL_PKGS[@]+"${FAIL_PKGS[@]}"}"; do
  fail "$p"
done

echo ""
echo -e "${BOLD}Packages :${RESET} ${#PASS_PKGS[@]} passed, ${#FAIL_PKGS[@]} failed"
echo -e "${BOLD}Tests    :${RESET} $TOTAL_TESTS"

if [ ${#FAIL_PKGS[@]} -gt 0 ]; then
  echo ""
  fail "Some packages have failing tests."
  exit 1
fi

echo ""
ok "All packages passed."
exit 0
