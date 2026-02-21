# AI Providers

ai-cmd supports three AI backends. All follow the same interface and can be swapped via a single environment variable.

## Selecting a Provider

```zsh
export AI_CMD_PROVIDER="anthropic"  # default
export AI_CMD_PROVIDER="openai"
export AI_CMD_PROVIDER="ollama"
```

## Anthropic (Claude) — Default

Uses the Anthropic Messages API with Claude models.

| Setting | Variable | Default |
|---------|----------|---------|
| API key | `ANTHROPIC_API_KEY` | (required) |
| Model | `AI_CMD_ANTHROPIC_MODEL` | `claude-haiku-4-5-20251001` |
| Timeout | `AI_CMD_TIMEOUT` | `30` seconds |

```zsh
export ANTHROPIC_API_KEY="sk-ant-..."
# Optionally override the model:
export AI_CMD_ANTHROPIC_MODEL="claude-sonnet-4-20250514"
```

## OpenAI (GPT)

Uses the OpenAI Chat Completions API. Also supports any OpenAI-compatible endpoint (e.g., Azure OpenAI, local proxies).

| Setting | Variable | Default |
|---------|----------|---------|
| API key | `OPENAI_API_KEY` | (required) |
| Model | `AI_CMD_OPENAI_MODEL` | `gpt-4o-mini` |
| Endpoint | `AI_CMD_OPENAI_ENDPOINT` | `https://api.openai.com/v1/chat/completions` |
| Timeout | `AI_CMD_TIMEOUT` | `30` seconds |

```zsh
export OPENAI_API_KEY="sk-..."
# Use a different model:
export AI_CMD_OPENAI_MODEL="gpt-4o"
# Use a compatible endpoint:
export AI_CMD_OPENAI_ENDPOINT="https://my-proxy.example.com/v1/chat/completions"
```

## Ollama (Local)

Uses a locally running Ollama instance. Free, fully offline, no API key needed.

| Setting | Variable | Default |
|---------|----------|---------|
| Model | `AI_CMD_OLLAMA_MODEL` | `llama3.2` |
| Endpoint | — | `http://localhost:11434/api/chat` |
| Timeout | `AI_CMD_TIMEOUT` | `60` seconds |

```zsh
# Make sure Ollama is running:
ollama serve

# Optionally use a different model:
export AI_CMD_OLLAMA_MODEL="mistral"
```

If the connection fails, ai-cmd will prompt: *"Is Ollama running? (ollama serve)"*.

## How Providers Work Internally

Each provider file (`providers/*.zsh`) defines a function `_ai-cmd-provider-<name>` that:

1. Receives two arguments: the user's natural language input and the gathered context
2. Constructs a JSON payload with a system prompt and user message
3. Calls the provider's API via `curl`
4. Extracts the response text using `jq`
5. Returns the raw command string (or an error message)

The system prompt sent to every provider emphasizes:
- Return **only** the command, no explanations or markdown
- Be aware of BSD vs GNU tool differences (especially on macOS)
- Use `&&` or pipes for multi-step commands
- Avoid dangerous commands unless explicitly requested
- Use the provided context (OS, PWD, available tools, files, git status)

## Adding a New Provider

1. Create `providers/yourprovider.zsh`
2. Define `_ai-cmd-provider-yourprovider` accepting `$1` (input) and `$2` (context)
3. Call the API, extract the response, and `echo` it
4. Add routing in `_ai-cmd-call-api`:
   ```zsh
   yourprovider) _ai-cmd-provider-yourprovider "$1" "$2" ;;
   ```
