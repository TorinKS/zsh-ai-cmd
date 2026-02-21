#!/usr/bin/env zsh
# ai-cmd provider: Anthropic Claude API

: ${AI_CMD_ANTHROPIC_MODEL:=claude-haiku-4-5-20251001}
: ${AI_CMD_ANTHROPIC_URL:=https://api.anthropic.com/v1/messages}

_ai-cmd-provider-anthropic() {
  local input="$1" context="$2"
  local api_key="${ANTHROPIC_API_KEY:-}"
  local timeout="${AI_CMD_TIMEOUT:-30}"

  if [[ -z "$api_key" ]]; then
    print -u2 "ai-cmd: ANTHROPIC_API_KEY is not set."
    print -u2 "  Export it in your .zshrc: export ANTHROPIC_API_KEY='sk-ant-...'"
    return 1
  fi

  local system_prompt="You are a shell command generator. The user describes a task in natural language. Output ONLY the shell command that accomplishes the task.
Rules:
- Output the raw command only. No markdown, no code fences, no backticks, no explanations, no comments.
- Use standard POSIX/GNU utilities available on the user's OS.
- If the task requires multiple commands, chain them with && or pipes.
- Never output dangerous commands unless the user explicitly asks for destructive operations.
- Use the provided context (OS, PWD, files) to generate accurate commands.

Context:
${context}"

  local payload
  payload=$(jq -n \
    --arg model "$AI_CMD_ANTHROPIC_MODEL" \
    --arg system "$system_prompt" \
    --arg input "$input" \
    '{
      model: $model,
      max_tokens: 256,
      system: $system,
      messages: [
        { role: "user", content: $input }
      ]
    }')

  local response
  response=$(curl -s --max-time "$timeout" \
    -H "Content-Type: application/json" \
    -H "x-api-key: ${api_key}" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" \
    "$AI_CMD_ANTHROPIC_URL" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    print -u2 "ai-cmd: API request failed (network error or timeout)"
    return 1
  fi

  local error_msg
  error_msg=$(print -r -- "$response" | jq -r '.error.message // empty')
  if [[ -n "$error_msg" ]]; then
    print -u2 "ai-cmd: API error: $error_msg"
    return 1
  fi

  local cmd
  cmd=$(print -r -- "$response" | jq -r '.content[0].text // empty')

  if [[ -z "$cmd" ]]; then
    print -u2 "ai-cmd: Empty response from API"
    return 1
  fi

  print -r -- "$cmd"
}
