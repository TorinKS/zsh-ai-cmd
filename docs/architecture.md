# Architecture

## Project Structure

```
ai-cmd/
├── ai-cmd.plugin.zsh          # Plugin entry point — bootstrap & config
├── functions/                  # Core zsh functions (autoloaded)
│   ├── _ai-cmd-accept-line    # Prefix trigger (intercepts Enter)
│   ├── _ai-cmd-keybind-trigger    # Keybinding trigger (Ctrl+X Ctrl+A)
│   ├── _ai-cmd-regenerate     # Ctrl+R regenerate widget
│   ├── _ai-cmd-context        # Environment context gatherer
│   ├── _ai-cmd-context-commit # Git diff context for commit messages
│   ├── _ai-cmd-call-api       # Provider router/dispatcher
│   ├── _ai-cmd-sanitize       # Response cleanup
│   └── _ai-cmd-safety         # Dangerous command detection
├── providers/                  # AI backend implementations
│   ├── anthropic.zsh          # Claude API
│   ├── openai.zsh             # OpenAI / compatible APIs
│   └── ollama.zsh             # Local Ollama
└── docs/                      # Documentation
```

## Design Principles

**Pure shell** — No Python, Node.js, or other runtimes. Only `curl` and `jq` as external dependencies.

**Human-in-the-loop** — Commands are never auto-executed. The generated command replaces the buffer and the user must press Enter to run it.

**Platform-aware** — Detects macOS/Linux, BSD vs GNU tools, and sends this context to the AI so generated commands work on the user's actual system.

**Provider-agnostic** — Swapping between Anthropic, OpenAI, or Ollama is a single environment variable change. All providers share the same interface.

**Safety by default** — 23 regex patterns detect destructive commands. Dangerous commands are highlighted red as a warning, but the user retains full control.

## Component Responsibilities

### Bootstrap (`ai-cmd.plugin.zsh`)

- Checks for required dependencies (`curl`, `jq`)
- Sets default configuration values
- Autoloads functions from `functions/`
- Sources provider files from `providers/`
- Hooks into zsh `precmd` to initialize ZLE widgets
- Overrides the `accept-line` widget to intercept Enter
- Binds the optional keybinding trigger

### Triggers

Three entry points:

| Component | Trigger | Input |
|-----------|---------|-------|
| `_ai-cmd-accept-line` | User presses Enter with `# ` prefix | Text after prefix |
| `_ai-cmd-keybind-trigger` | User presses Ctrl+X Ctrl+A | Entire buffer |
| `_ai-cmd-regenerate` | User presses Ctrl+R after generation | Re-sends last input |

`_ai-cmd-accept-line` detects special keywords to switch modes:

| Keyword | Mode | Context Function |
|---------|------|------------------|
| `commit` | Commit message generation | `_ai-cmd-context-commit` |
| `pr` | PR creation | Inline context in `_ai-cmd-accept-line` |
| (anything else) | Natural language → command | `_ai-cmd-context` |

### Context

Two context gatherers, selected by mode:

**`_ai-cmd-context`** — Builds a text block with system information (OS, PWD, git status, shell history). Used for natural language → command translation.

**`_ai-cmd-context-commit`** — Gathers git diff, branch name, recent commits, and reads `.ai-cmd` config for commit style. Used for `# commit` mode. Outputs a `NEEDS_STAGING` marker when no staged changes exist, signaling `_ai-cmd-accept-line` to prepend `git add -u &&`.

### Router (`_ai-cmd-call-api`)

A simple switch that dispatches to the correct provider function based on `AI_CMD_PROVIDER`.

### Providers (`providers/*.zsh`)

Each provider:
1. Builds a JSON payload with system prompt + user input + context
2. Sends it via `curl`
3. Parses the response with `jq`
4. Returns the raw command string

### Sanitizer (`_ai-cmd-sanitize`)

Cleans AI responses: strips markdown, backticks, ANSI codes, and chains multi-line output into a single executable line.

### Safety (`_ai-cmd-safety`)

Pattern-matches the generated command against known dangerous patterns. Returns exit code 1 if a match is found, which triggers red highlighting in the UI.

### Per-Project Config (`.ai-cmd`)

A simple key=value file in the git repo root. Currently supports:

| Key | Values | Default |
|-----|--------|---------|
| `commit_style` | `conventional`, `simple` | `conventional` |

Read by `_ai-cmd-context-commit` to customize the commit message format instruction sent to the AI.

## Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_CMD_PROVIDER` | `anthropic` | AI backend: `anthropic`, `openai`, `ollama` |
| `AI_CMD_PREFIX` | `"# "` | Prefix that triggers translation on Enter |
| `AI_CMD_KEYBINDING` | `"^X^A"` | Keybinding for direct trigger |
| `AI_CMD_TIMEOUT` | `30` (60 for ollama) | API call timeout in seconds |
| `AI_CMD_SAFETY` | `1` | Enable (`1`) or disable (`0`) safety checks |
| `ANTHROPIC_API_KEY` | — | API key for Anthropic provider |
| `AI_CMD_ANTHROPIC_MODEL` | `claude-haiku-4-5-20251001` | Anthropic model |
| `OPENAI_API_KEY` | — | API key for OpenAI provider |
| `AI_CMD_OPENAI_MODEL` | `gpt-4o-mini` | OpenAI model |
| `AI_CMD_OPENAI_ENDPOINT` | `https://api.openai.com/v1/chat/completions` | OpenAI-compatible endpoint |
| `AI_CMD_OLLAMA_MODEL` | `llama3.2` | Ollama model |
