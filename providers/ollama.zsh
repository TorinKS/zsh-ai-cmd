#!/usr/bin/env zsh
# ai-cmd provider: Local Ollama instance (free, offline)

: ${AI_CMD_OLLAMA_MODEL:=llama3.2}
: ${AI_CMD_OLLAMA_URL:=http://localhost:11434/api/chat}

_ai-cmd-provider-ollama() {
  local input="$1" context="$2"
  local timeout="${AI_CMD_TIMEOUT:-60}"

  local system_prompt="You are a shell command generator. The user describes a task in natural language. Output ONLY the shell command that accomplishes the task.
Rules:
- Output the raw command only. No markdown, no code fences, no backticks, no explanations, no comments.
- CRITICAL: Read the Platform field in the context below. If it says macOS/BSD, you MUST use BSD-compatible flags and syntax. Do NOT use GNU/Linux-only options (e.g. ps --sort, grep --color=always, sed -i without '', readlink -f, etc.). macOS uses BSD coreutils, not GNU.
- If the task requires multiple commands, chain them with && or pipes.
- Never output dangerous commands unless the user explicitly asks for destructive operations.
- Use the provided context (OS, PWD, files, available tools) to generate accurate commands.

Context:
${context}"

  local payload
  payload=$(jq -n \
    --arg model "$AI_CMD_OLLAMA_MODEL" \
    --arg system "$system_prompt" \
    --arg input "$input" \
    '{
      model: $model,
      stream: false,
      messages: [
        { role: "system", content: $system },
        { role: "user", content: $input }
      ]
    }')

  local response
  response=$(curl -s --max-time "$timeout" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$AI_CMD_OLLAMA_URL" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    print -u2 "ai-cmd: Ollama request failed. Is Ollama running? (ollama serve)"
    return 1
  fi

  local cmd
  cmd=$(print -r -- "$response" | jq -r '.message.content // empty')

  if [[ -z "$cmd" ]]; then
    print -u2 "ai-cmd: Empty response from Ollama"
    return 1
  fi

  print -r -- "$cmd"
}
