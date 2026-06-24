---
name: genv
description: Install `genv`, a focused GitHub CLI wrapper for managing a repo's GitHub Actions environment variables and secrets — `genv pull`/`genv push` sync variables to/from .env files, and `genv secret` sets secrets with optional fallback variables. Use when someone wants to install or set up genv, manage GitHub Actions env vars/secrets from the command line, or when the genv command is not found.
---

# Setup: genv

`genv` is a small command-line tool — a thin wrapper over the GitHub CLI (`gh`) — for managing a repo's **GitHub Actions configuration** without the noise of all of `gh`'s other commands:

- `genv pull [-e <env>] [-f <file>]` — write GitHub **variables** into a dotenv file (default `.env`)
- `genv push [-e <env>] [-f <file>]` — set GitHub **variables** from a dotenv file (default `.env`)
- `genv secret <NAME> [value] [--fallback <value>] [-e <env>]` — set a **secret**, optionally with a fallback variable

With no `-e`, they target **repository-level** config; with `-e <name>`, the named **environment** (e.g. `production`).

## The variables-vs-secrets model

GitHub treats the two stores differently, and that drives the workflow:

| | Variables | Secrets |
|---|---|---|
| Read values back | ✅ (`genv pull` works) | ❌ never — write-only |
| Use for | non-sensitive config + **fallback defaults** | sensitive values |

Because secrets can't be read back, the pattern is: store the real value as a **secret**, and (optionally) a non-sensitive default as a same-named **variable**. The workflow then resolves secret-or-fallback at runtime:

```yaml
# .github/workflows/*.yml
env:
  API_KEY: ${{ secrets.API_KEY || vars.API_KEY }}   # secret wins; empty/unset falls back to the variable
```

`genv secret NAME val --fallback default` sets both sides of that expression in one command.

## What to do

Run these in order. If a prerequisite is missing, surface the instruction to the user and stop — do **not** try to auto-fix authentication.

### 1. Check the GitHub CLI is installed (genv wraps it)

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

### 3. Install genv

Run the bundled installer (`install.sh`, in this skill's own directory). It re-checks the prerequisites, copies `genv` onto your PATH, and is safe to re-run:

```sh
bash install.sh
```

It installs to `~/.local/bin/genv` by default (override with `GENV_BIN_DIR=/some/dir`). If it reports that the install dir isn't on your PATH, add the printed `export PATH=...` line to your shell profile (`~/.zshrc` / `~/.bashrc`) and restart your shell.

### 4. Confirm `.env*` files are gitignored

`genv pull`/`push` read and write dotenv files that may contain real values. Make sure they can never be committed — the `.gitignore` should ignore `.env` and friends (e.g. a `.env*` pattern, with `!.env.example` if a sample is tracked).

### 5. Verify

```sh
genv --help
```

It should print the genv help. Report success and show the usage examples below.

## Usage (share with the user)

```sh
# Variables (readable; round-trip with .env files)
genv pull                          # repo-level variables → .env
genv pull -e production            # production variables → .env
genv push -e staging -f .env.stg   # .env.stg → staging variables

# Secrets (write-only) + optional fallback variable
genv secret API_KEY sk-real --fallback sk-dummy -e production
#   → secret  API_KEY = sk-real   (real value, not readable back)
#   → variable API_KEY = sk-dummy  (public fallback, readable)

genv secret API_KEY --fallback sk-dummy -e production    # omit value → read secret from stdin
printf '%s' "sk-real" | genv secret API_KEY -e production # pipe it in (stays out of shell history)
```

Notes:
- **Keep secret values out of shell history**: omit the value argument and pipe/redirect it via stdin (a single trailing newline is trimmed automatically).
- Secrets are write-only — there is intentionally no "pull" for secrets. `genv pull` only ever returns variables.
- `genv push` and `genv secret --fallback` only add/update the keys you give them; they never delete config you removed.
- In the workflow, resolve the pair once into `env:` with `${{ secrets.NAME || vars.NAME }}` and the rest of the job just uses the env var.
- `genv --help` (and `genv <command> --help`) document everything; no need to remember flags.
```
