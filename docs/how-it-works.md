# How ai-cmd Works

ai-cmd is a zsh plugin that translates natural language into executable shell commands using AI. It hooks into the zsh line editor (ZLE) so you can type what you want in plain English and get a real command back — without leaving your terminal.

## Quick Example

```
# find all files larger than 100MB in home directory
```

Press **Enter** and ai-cmd replaces it with:

```
find ~ -type f -size +100M -exec ls -lh {} \;
```

The command is highlighted green (safe) or red (dangerous). You review it, then press Enter to execute or Ctrl+C to cancel.

## How It Triggers

There are two ways to invoke ai-cmd:

### 1. Prefix mode (default)

Type a line starting with `# ` (configurable via `AI_CMD_PREFIX`), then press Enter. The plugin intercepts the Enter key, strips the prefix, and sends the rest to the AI.

Handled by: `_ai-cmd-accept-line`

### 2. Keybinding mode

Type anything in the buffer and press **Ctrl+X Ctrl+A** (configurable via `AI_CMD_KEYBINDING`). The entire buffer content is sent to the AI.

Handled by: `_ai-cmd-keybind-trigger`

## End-to-End Flow

```
User types: "# list docker containers sorted by size"
                          |
                          v
              +-----------+-----------+
              | Trigger Detection     |
              | (accept-line or       |
              |  keybind-trigger)     |
              +-----------+-----------+
                          |
                          v
              +-----------+-----------+
              | Context Gathering     |
              | (_ai-cmd-context)     |
              | - OS & platform       |
              | - BSD vs GNU tools    |
              | - PWD, user, shell    |
              | - Directory listing   |
              | - Git branch/status   |
              | - Recent commands     |
              +-----------+-----------+
                          |
                          v
              +-----------+-----------+
              | API Call              |
              | (_ai-cmd-call-api)    |
              |  routes to provider:  |
              |  - anthropic (Claude) |
              |  - openai (GPT)      |
              |  - ollama (local)     |
              +-----------+-----------+
                          |
                          v
              +-----------+-----------+
              | Sanitize Response     |
              | (_ai-cmd-sanitize)    |
              | - Strip markdown      |
              | - Remove backticks    |
              | - Strip ANSI codes    |
              | - Chain multi-line    |
              |   commands with &&    |
              +-----------+-----------+
                          |
                          v
              +-----------+-----------+
              | Safety Check          |
              | (_ai-cmd-safety)      |
              | 23 dangerous patterns |
              | like rm -rf /, fork   |
              | bombs, curl|sh, etc.  |
              +-----------+-----------+
                          |
                    +-----+-----+
                    |           |
                    v           v
                 [safe]     [dangerous]
                 GREEN       RED
                highlight   highlight
                + [ok]      + WARNING
                          |
                          v
              User reviews & decides:
              Enter = execute
              Ctrl+C = cancel
```

## Context Awareness

Before calling the AI, `_ai-cmd-context` gathers information about your environment:

| Context         | What it captures                              |
|-----------------|-----------------------------------------------|
| Platform        | macOS or Linux, with version                  |
| Tool flavor     | BSD (macOS default) vs GNU userland            |
| Available tools | Detects gfind, gsed, gawk, gsort, homebrew    |
| Shell           | zsh version                                   |
| Working dir     | Current directory path                        |
| Files           | First 20 entries in current directory          |
| Git             | Current branch and status (if in a repo)       |
| History         | Last 5 commands from shell history             |

This context is sent alongside your request so the AI generates commands that actually work on your system — for example, using BSD-compatible flags on macOS or suggesting `gfind` when GNU find is available.

## Response Sanitization

AI models often return extra formatting. `_ai-cmd-sanitize` cleans the response:

1. Strips markdown code fences (`` ```bash ... ``` ``)
2. Removes inline backticks
3. Strips ANSI escape sequences
4. Trims whitespace
5. For multi-line responses:
   - Filters out comment lines (starting with `#`)
   - Filters out explanatory text ("Note:", "This ", "The ")
   - Chains remaining commands with `&&`

The result is a clean, executable command placed in your terminal buffer.

## Safety Detection

`_ai-cmd-safety` scans the generated command against 23 dangerous patterns:

- **Destructive file ops**: `rm -rf /`, `rm -rf ~`, `rm -rf *`
- **Disk operations**: `mkfs`, `dd if=... of=/dev/*`, `wipefs`, `diskutil eraseDisk`
- **Permission bombs**: `chmod -R 777 /`
- **Data destruction**: `find ... -delete`, `mv ... /dev/null`
- **Remote code execution**: `wget ... | sh`, `curl ... | sh`
- **System shutdown**: `shutdown`, `reboot`, `halt`, `poweroff`, `init 0/6`
- **Fork bombs**: `:(){ :|:& };:`
- **Disk overwrite**: `> /dev/sd*`

Dangerous commands are still shown (highlighted in red) — the user always has the final say.

## Dependencies

Only two external tools are required:

- **curl** — for making API calls to providers
- **jq** — for parsing JSON responses
