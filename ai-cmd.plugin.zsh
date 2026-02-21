#!/usr/bin/env zsh
# ai-cmd — Natural language to shell command translation
# https://github.com/USERNAME/ai-cmd

# Reliable $0 detection (Zsh Plugin Standard)
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"
typeset -g AI_CMD_DIR="${0:h}"

# --- Dependency check ---
if ! command -v curl &>/dev/null; then
  print -u2 "ai-cmd: 'curl' is required but not found."
  return 1
fi
if ! command -v jq &>/dev/null; then
  print -u2 "ai-cmd: 'jq' is required but not found."
  print -u2 "  Install: brew install jq (macOS) / apt install jq (Linux)"
  return 1
fi

# --- Configuration defaults ---
: ${AI_CMD_PROVIDER:=anthropic}
: ${AI_CMD_PREFIX:="# "}
: ${AI_CMD_KEYBINDING:="^X^A"}
: ${AI_CMD_TIMEOUT:=30}
: ${AI_CMD_SAFETY:=true}
: ${AI_CMD_DEBUG:=false}

# --- Autoload functions ---
fpath=("${AI_CMD_DIR}/functions" $fpath)
autoload -Uz _ai-cmd-accept-line
autoload -Uz _ai-cmd-keybind-trigger
autoload -Uz _ai-cmd-call-api
autoload -Uz _ai-cmd-context
autoload -Uz _ai-cmd-safety
autoload -Uz _ai-cmd-sanitize

# --- Source providers ---
source "${AI_CMD_DIR}/providers/anthropic.zsh"
source "${AI_CMD_DIR}/providers/openai.zsh"
source "${AI_CMD_DIR}/providers/ollama.zsh"

# --- Deferred ZLE initialization ---
_ai-cmd-precmd-init() {
  add-zsh-hook -d precmd _ai-cmd-precmd-init

  zle -N accept-line _ai-cmd-accept-line

  if [[ -n "$AI_CMD_KEYBINDING" ]]; then
    zle -N _ai-cmd-keybind-trigger
    bindkey "$AI_CMD_KEYBINDING" _ai-cmd-keybind-trigger
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ai-cmd-precmd-init
