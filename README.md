# ai-cmd

Type English in your terminal. Get shell commands back.

```
$ # find all files larger than 100MB in home directory
  ... translating to command
$ find ~ -type f -size +100M -exec ls -lh {} \;
  [ok] Press Enter to execute, Ctrl+C to cancel
```

A zsh plugin that intercepts natural language descriptions and translates them into real shell commands using AI. No Python, no Node — just zsh, curl, and jq.

## How It Works

1. Type `# ` followed by what you want to do in plain English
2. Press **Enter**
3. The plugin sends your description to an AI model with context (OS, directory, git status, recent commands)
4. The generated command replaces your input — highlighted in green (or red if dangerous)
5. Review the command, then press **Enter** to execute, **Ctrl+R** to regenerate, or **Ctrl+C** to cancel

Alternatively, type anything and press **Ctrl+X Ctrl+A** to translate the current line.

## Git Commit Messages

Generate conventional commit messages from your staged or unstaged changes:

```
$ # commit
  ... generating commit message
$ git commit -m "feat(auth): add login endpoint"
  [ok] Press Enter to execute, Ctrl+R to regenerate, Ctrl+C to cancel
```

If no changes are staged, the plugin auto-prepends `git add -u &&` to stage tracked files first.

Add a hint to guide the message:

```
$ # commit fix the login bug
```

## PR Creation

Generate `gh pr create` commands from your branch context:

```
$ # pr
  ... generating PR command
$ gh pr create --title "feat: add commit generation" --body "..."
  [ok] Press Enter to execute, Ctrl+R to regenerate, Ctrl+C to cancel
```

The plugin gathers commits since the base branch, diff stats, and branch name to generate an appropriate PR title and body. Requires `gh` CLI.

## Installation

### Oh-My-Zsh

```bash
git clone https://github.com/TorinKS/zsh-ai-cmd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ai-cmd
```

Add to your `~/.zshrc`:

```zsh
plugins=(... ai-cmd)
```

### Zinit

```zsh
zinit light TorinKS/zsh-ai-cmd
```

### Antigen

```zsh
antigen bundle TorinKS/zsh-ai-cmd
```

### Manual

```zsh
source /path/to/ai-cmd/ai-cmd.plugin.zsh
```

## Configuration

Add to your `~/.zshrc` before the plugin loads:

```zsh
# Required: API key for your chosen provider
export ANTHROPIC_API_KEY="sk-ant-..."

# Optional: defaults shown
export AI_CMD_PROVIDER=anthropic          # anthropic | openai | ollama
export AI_CMD_PREFIX="# "                 # trigger prefix (must end with space)
export AI_CMD_KEYBINDING="^X^A"           # Ctrl+X Ctrl+A (set empty to disable)
export AI_CMD_TIMEOUT=30                  # API timeout in seconds
export AI_CMD_SAFETY=true                 # warn on dangerous commands

# Provider-specific
export AI_CMD_ANTHROPIC_MODEL=claude-haiku-4-5-20251001
export AI_CMD_OPENAI_MODEL=gpt-4o-mini
export AI_CMD_OLLAMA_MODEL=llama3.2
```

## Providers

**Anthropic Claude** (default) — fast, cheap (~$0.30/month at typical usage). Requires `ANTHROPIC_API_KEY`.

**OpenAI** — set `AI_CMD_PROVIDER=openai` and `OPENAI_API_KEY`. Also works with OpenAI-compatible endpoints by setting `AI_CMD_OPENAI_URL`.

**Ollama** (local) — free, fully offline. Set `AI_CMD_PROVIDER=ollama`. Requires Ollama running locally (`ollama serve`).

## Dependencies

- `curl` — pre-installed on macOS and most Linux
- `jq` — install with `brew install jq` (macOS) or `apt install jq` (Linux)

## Safety

Generated commands are checked against a list of dangerous patterns (`rm -rf /`, `mkfs`, `dd` to disk, fork bombs, etc.). Dangerous commands are highlighted in **red** with a warning. You always review before execution — nothing runs without your second Enter press.

## Per-Project Config

Create a `.ai-cmd` file in your repo root to customize behavior per project:

```
commit_style=conventional
```

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `commit_style` | `conventional`, `simple` | `conventional` | Commit message format |

- `conventional` — `feat(scope): description`, `fix(scope): description`, etc.
- `simple` — plain descriptions like `add login endpoint`

## Regenerate

Press **Ctrl+R** after a command is generated to regenerate it with the same input. Useful for getting a different commit message or command variation.

## Examples

```
$ # show disk usage sorted by size
$ du -sh * | sort -rh

$ # kill the process on port 3000
$ lsof -ti:3000 | xargs kill -9

$ # compress all png files in current directory
$ tar -czf images.tar.gz *.png

$ # show git commits from last week by me
$ git log --oneline --after="1 week ago" --author="$(git config user.name)"

$ # find and replace foo with bar in all python files
$ find . -name "*.py" -exec sed -i '' 's/foo/bar/g' {} +

$ # commit
$ git commit -m "feat(api): add rate limiting middleware"

$ # commit fix the typo in readme
$ git commit -m "docs: fix typo in README"

$ # pr
$ gh pr create --title "feat: add rate limiting" --body "..."
```

## License

MIT
