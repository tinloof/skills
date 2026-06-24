#!/usr/bin/env bash
#
# Installs the team's GitHub CLI aliases for managing a repo's Actions config:
#   env-pull    GitHub variables        -> .env file
#   env-push    .env file               -> GitHub variables
#   secret-set  set one secret (+ optional fallback variable of the same name)
#
# All are repo-level by default, or environment-scoped with -e <env>.
# Idempotent: re-running clobbers any existing aliases of the same name.

set -euo pipefail

# 1. Ensure the GitHub CLI is installed.
if ! command -v gh >/dev/null 2>&1; then
  echo "✗ GitHub CLI (gh) is not installed."
  case "$(uname -s)" in
    Darwin) echo "  Install it with:  brew install gh" ;;
    Linux)  echo "  Install guide:    https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
    *)      echo "  Install guide:    https://cli.github.com" ;;
  esac
  exit 1
fi
echo "✓ gh installed — $(gh --version | head -n1)"

# 2. Ensure gh is authenticated.
if ! gh auth status >/dev/null 2>&1; then
  echo "✗ Not logged in to GitHub. Run:  gh auth login"
  exit 1
fi
echo "✓ gh authenticated"

# 3. Install the aliases. The bodies are single-quoted so their $#, $1, ${e:+...},
#    $(...) etc. are stored verbatim in the alias rather than expanded here. The
#    '\'' sequences are literal single quotes wrapping the jq filter.
gh alias set --clobber env-pull --shell 'e= f=.env; while [ $# -gt 0 ]; do case "$1" in -e|--env) e="$2"; shift 2;; -f|--file) f="$2"; shift 2;; *) shift;; esac; done; gh variable list ${e:+--env "$e"} --json name,value --jq '\''.[] | "\(.name)=\(.value)"'\'' > "$f" && echo "✓ wrote $(grep -c . "$f") var(s) to $f"'

gh alias set --clobber env-push --shell 'e= f=.env; while [ $# -gt 0 ]; do case "$1" in -e|--env) e="$2"; shift 2;; -f|--file) f="$2"; shift 2;; *) shift;; esac; done; gh variable set --env-file "$f" ${e:+--env "$e"} && echo "✓ pushed $f to ${e:-repo}"'

# secret-set NAME [value] [--fallback <value>] [-e <env>]
#   Sets secret NAME. If <value> is omitted, the secret is read from stdin (keeps
#   it out of shell history). --fallback also sets a same-named variable, so a
#   workflow can resolve it as: ${{ secrets.NAME || vars.NAME }}.
gh alias set --clobber secret-set --shell 'n= v= fb= e= vset=; while [ $# -gt 0 ]; do case "$1" in -e|--env) e="$2"; shift 2;; --fallback) fb="$2"; shift 2;; *) if [ -z "$n" ]; then n="$1"; else v="$1"; vset=1; fi; shift;; esac; done; if [ -n "$vset" ]; then gh secret set "$n" -b "$v" ${e:+--env "$e"}; else gh secret set "$n" ${e:+--env "$e"}; fi && { [ -z "$fb" ] || gh variable set "$n" -b "$fb" ${e:+--env "$e"}; } && echo "✓ set secret $n${e:+ (env $e)}${fb:+ + fallback var}"'

echo "✓ installed aliases: env-pull, env-push, secret-set"

# 4. Confirm.
echo
echo "Done. Usage:"
echo "  gh env-pull   [-e <env>] [-f <file>]            # GitHub variables → file (default .env)"
echo "  gh env-push   [-e <env>] [-f <file>]            # file → GitHub variables (default .env)"
echo "  gh secret-set <NAME> [value] [--fallback <v>] [-e <env>]   # set secret (value via stdin if omitted)"
