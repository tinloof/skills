# Tinloof Skills

Agent skills published by [Tinloof](https://tinloof.com), installable with the
[`skills`](https://www.skills.sh) CLI.

## Install

```sh
npx skills add tinloof/skills
```

This installs the skills below into your project's `.claude/skills/`. Your agent
then picks them up automatically.

## Skills

### `setup-gh-env-aliases`

Installs three GitHub CLI aliases for managing a repo's **GitHub Actions
configuration** from the command line:

| Alias | What it does |
| --- | --- |
| `gh env-pull [-e <env>] [-f <file>]` | GitHub **variables** → dotenv file (default `.env`) |
| `gh env-push [-e <env>] [-f <file>]` | dotenv file → GitHub **variables** |
| `gh secret-set <NAME> [value] [--fallback <v>] [-e <env>]` | set a **secret**, plus an optional same-named fallback variable |

No `-e` targets repository-level config; `-e <name>` targets an environment
(e.g. `production`). Secrets are write-only; pair a secret with a `--fallback`
variable and resolve it in a workflow as `${{ secrets.NAME || vars.NAME }}`.

After installing, just ask your agent to **"set up the gh env aliases"** — the
skill checks that `gh` is installed and authenticated, then runs its bundled
`install.sh`.
