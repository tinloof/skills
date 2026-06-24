#!/usr/bin/env bash
#
# Installs `genv` — a focused GitHub CLI wrapper for managing a repo's Actions
# env vars & secrets (genv pull / push / secret). genv wraps `gh`.
#
# Idempotent: re-running overwrites the installed script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${GENV_BIN_DIR:-$HOME/.local/bin}"
TARGET="$BIN_DIR/genv"

# 1. gh must be installed (genv wraps it).
if ! command -v gh >/dev/null 2>&1; then
  echo "✗ GitHub CLI (gh) is not installed — genv wraps it."
  case "$(uname -s)" in
    Darwin) echo "  Install it with:  brew install gh" ;;
    Linux)  echo "  Install guide:    https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
    *)      echo "  Install guide:    https://cli.github.com" ;;
  esac
  exit 1
fi
echo "✓ gh installed — $(gh --version | head -n1)"

# 2. gh must be authenticated.
if ! gh auth status >/dev/null 2>&1; then
  echo "✗ Not logged in to GitHub. Run:  gh auth login"
  exit 1
fi
echo "✓ gh authenticated"

# 3. Install genv onto PATH.
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/genv" "$TARGET"
chmod 0755 "$TARGET"
echo "✓ installed genv → $TARGET"

# 4. Make sure the target dir is on PATH.
case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "✓ $BIN_DIR is on your PATH" ;;
  *)
    echo "⚠ $BIN_DIR is not on your PATH yet. Add this to your shell profile"
    echo "  (~/.zshrc or ~/.bashrc), then restart your shell:"
    echo
    echo "      export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo
echo "Done. Try:  genv --help"
