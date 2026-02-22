#!/usr/bin/env zsh
# Install zsh-ai-cmd to the Oh-My-Zsh custom plugins directory
# Usage: ./install.sh

set -e

PLUGIN_NAME="ai-cmd"

# Determine target directory
if [[ -n "$ZSH_CUSTOM" ]]; then
  TARGET="${ZSH_CUSTOM}/plugins/${PLUGIN_NAME}"
elif [[ -d "$HOME/.oh-my-zsh/custom" ]]; then
  TARGET="$HOME/.oh-my-zsh/custom/plugins/${PLUGIN_NAME}"
else
  TARGET="$HOME/.zsh-${PLUGIN_NAME}"
fi

SOURCE_DIR="${0:A:h}"

echo "Installing ${PLUGIN_NAME} to ${TARGET} ..."

mkdir -p "${TARGET}/functions"
mkdir -p "${TARGET}/providers"

cp "${SOURCE_DIR}/ai-cmd.plugin.zsh" "${TARGET}/"
cp "${SOURCE_DIR}"/functions/_ai-cmd-* "${TARGET}/functions/"
cp "${SOURCE_DIR}"/providers/*.zsh "${TARGET}/providers/"

echo "Done."
echo ""
echo "Add to your ~/.zshrc:"
if [[ "$TARGET" == *"oh-my-zsh"* ]]; then
  echo "  plugins=(... ${PLUGIN_NAME})"
else
  echo "  source ${TARGET}/ai-cmd.plugin.zsh"
fi
echo ""
echo "Then set your API key:"
echo "  export ANTHROPIC_API_KEY=\"sk-ant-...\""
