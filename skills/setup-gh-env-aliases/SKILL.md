---
name: setup-gh-env-aliases
description: Install the team's GitHub CLI aliases (`gh env-pull`, `gh env-push`, `gh secret-set`) for syncing a repo's GitHub Actions variables to/from .env files and setting secrets with optional fallback variables. Use when someone wants to set up, install, or configure these env/secret aliases, onboard to the team's env workflow, or sees "unknown command env-pull / env-push / secret-set".
---

# Setup: gh env / secret aliases

Three GitHub CLI aliases for managing a repo's **Actions configuration**:

- `gh env-pull [-e <env>] [-f <file>]` — write GitHub **variables** into a dotenv file (default `.env`)
- `gh env-push [-e <env>] [-f <file>]` — set GitHub **variables** from a dotenv file (default `.env`)
- `gh secret-set <NAME> [value] [--fallback <value>] [-e <env>]` — set one **secret**, optionally with a fallback variable

With no `-e`, they target **repository-level** config; with `-e <name>`, the named **environment** (e.g. `production`).

## The variables-vs-secrets model

GitHub treats the two stores differently, and that drives the workflow:

| | Variables | Secrets |
|---|---|---|
| Read values back | ✅ (`env-pull` works) | ❌ never — write-only |
| Use for | non-sensitive config + **fallback defaults** | sensitive values |

Because secrets can't be read back, the pattern is: store the real value as a **secret**, and (optionally) a non-sensitive default as a same-named **variable**. The workflow then resolves secret-or-fallback at runtime:

```yaml
# .github/workflows/*.yml
env:
  API_KEY: ${{ secrets.API_KEY || vars.API_KEY }}   # secret wins; empty/unset falls back to the variable
```

`gh secret-set NAME val --fallback default` sets both sides of that expression in one command.

## What to do

Run these in order. If a prerequisite is missing, surface the instruction to the user and stop — do **not** try to auto-fix authentication.

### 1. Check the GitHub CLI is installed

```sh
command -v gh && gh --version | head -n1
```

If `gh` is not found, tell the user to install it, then stop:
- macOS: `brew install gh`
- Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
- Windows: `winget install --id GitHub.cli`

### 2. Check authentication

```sh
gh auth status
```

If this fails, **do not run `gh auth login` yourself** — it is interactive and will hang the session. Ask the user to run it themselves (in Claude Code: type `! gh auth login`), then continue once they confirm.

### 3. Install the aliases

Run the installer bundled with this skill (`install.sh`, in this skill's own directory). It re-checks the prerequisites above and is safe to re-run — it clobbers existing aliases of the same name:

```sh
bash install.sh        # run from this skill's directory
```

The alias definitions live in that script — read it if you need to inspect or troubleshoot them.

### 4. Confirm `.env*` files are gitignored

These tools read/write dotenv files that may contain real values. Make sure they can never be committed — the `.gitignore` should ignore `.env` and friends (e.g. a `.env*` pattern, with `!.env.example` if a sample is tracked).

### 5. Verify

```sh
gh alias list | grep -E 'env-(pull|push)|secret-set'
```

All three should be listed. Report success and show the usage examples below.

## Usage (share with the user)

```sh
# Variables (readable; round-trip with .env files)
gh env-pull                          # repo-level variables → .env
gh env-pull -e production            # production variables → .env
gh env-push -e staging -f .env.stg   # .env.stg → staging variables

# Secrets (write-only) + optional fallback variable
gh secret-set API_KEY "sk-real" --fallback "sk-dummy" -e production
#   → secret  API_KEY = sk-real   (real value, not readable back)
#   → variable API_KEY = sk-dummy  (public fallback, readable)

gh secret-set API_KEY --fallback "sk-dummy" -e production   # omit value → read secret from stdin
printf '%s' "sk-real" | gh secret-set API_KEY -e production # pipe it in (stays out of shell history)
```

Notes:
- **Keep secret values out of shell history**: omit the value argument and pipe/redirect it via stdin (a single trailing newline is trimmed automatically).
- Secrets are write-only — there is intentionally no "secret-pull". `env-pull` only ever returns variables.
- `env-push` and `secret-set --fallback` only add/update keys you give them; they never delete config you removed.
- In the workflow, resolve the pair once into `env:` with `${{ secrets.NAME || vars.NAME }}` and the rest of the job just uses the env var.
