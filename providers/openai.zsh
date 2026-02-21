#!/usr/bin/env zsh
# ai-cmd provider: OpenAI API (also works with OpenAI-compatible endpoints)

: ${AI_CMD_OPENAI_MODEL:=gpt-4o-mini}
: ${AI_CMD_OPENAI_URL:=https://api.openai.com/v1/chat/completions}

_ai-cmd-provider-openai() {
  local input="$1" context="$2"
  local api_key="${OPENAI_API_KEY:-}"
  local timeout="${AI_CMD_TIMEOUT:-30}"

  if [[ -z "$api_key" ]]; then
    print -u2 "ai-cmd: OPENAI_API_KEY is not set."
    print -u2 "  Export it in your .zshrc: export OPENAI_API_KEY='sk-...'"
    return 1
  fi

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
    --arg model "$AI_CMD_OPENAI_MODEL" \
    --arg system "$system_prompt" \
    --arg input "$input" \
    '{
      model: $model,
      max_completion_tokens: 256,
      temperature: 0,
      messages: [
        { role: "system", content: $system },
        { role: "user", content: $input }
      ]
    }')

  local response
  response=$(curl -s --max-time "$timeout" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${api_key}" \
    -d "$payload" \
    "$AI_CMD_OPENAI_URL" 2>/dev/null)

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
  cmd=$(print -r -- "$response" | jq -r '.choices[0].message.content // empty')

  if [[ -z "$cmd" ]]; then
    print -u2 "ai-cmd: Empty response from API"
    return 1
  fi

  print -r -- "$cmd"
}
