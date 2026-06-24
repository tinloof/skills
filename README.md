# Tinloof Skills

Agent skills published by [Tinloof](https://tinloof.com), installable with the
[`skills`](https://www.skills.sh) CLI.

## Install

```sh
npx skills add tinloof/skills
```

This installs the skills below into your project (`.agents/skills/`, symlinked for
Claude Code, Cursor, and others). Your agent picks them up automatically — just ask
it to set the skill up.

## Skills

### `genv`

A focused GitHub CLI wrapper for managing a repo's **GitHub Actions configuration**
without the noise of all of `gh`'s other commands. It installs a single `genv`
command:

| Command | What it does |
| --- | --- |
| `genv pull [-e <env>] [-f <file>]` | Write GitHub **variables** → dotenv file (default `.env`) |
| `genv push [-e <env>] [-f <file>]` | Set GitHub **variables** from a dotenv file |
| `genv secret <NAME> [value] [--fallback <v>] [-e <env>]` | Set a **secret**, with an optional same-named fallback variable |

- No `-e` targets **repository-level** config; `-e <name>` targets an **environment** (e.g. `production`).
- **Secrets are write-only.** Pair a secret with a `--fallback` variable and resolve it in a workflow as `${{ secrets.NAME || vars.NAME }}`.
- Omit the secret value to read it from **stdin** (keeps it out of shell history): `printf '%s' "$TOKEN" | genv secret API_KEY -e production`.
- `push` / `secret` **create the environment automatically** if it doesn't exist (a notice is printed, so a typo'd env name is visible).
- `genv --help` and `genv <command> --help` document everything.

**Setup** — ask your agent to *"set up genv"*, or run the bundled installer directly:

```sh
bash <skill-dir>/install.sh
```

It verifies `gh` is installed and authenticated, then drops `genv` into
`~/.local/bin` (override with `GENV_BIN_DIR=/some/dir`).

**Requirements** — the [GitHub CLI](https://cli.github.com) (`gh`), authenticated
via `gh auth login`, and a `bash` shell. On Windows that means **Git Bash or WSL**;
`genv` is a bash script and won't run in native PowerShell/cmd.
