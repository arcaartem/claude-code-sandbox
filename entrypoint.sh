#!/bin/bash
set -e

# Set up PATH
export PATH="$HOME/.local/bin:$PATH"

cd /workspace

echo "🚀 Development environment ready!"
echo "📁 Working directory: $(pwd)"
echo "🛠️  Available tools: mise, claude"
echo ""

# Auto-detect and setup mise tools if .mise.toml exists
if [ -f ".mise.toml" ]; then
    echo "📋 Found .mise.toml, installing tools..."
    mise install
    echo "✅ Tools installed successfully!"
    echo ""
fi

# Start Claude Code by default, or run specified command
if [ "$#" -eq 0 ] || [ "$1" = "claude" ]; then
    echo "🤖 Starting Claude Code..."
    exec claude
elif [ "$1" = "claude-no-prompts" ]; then
    echo "🤖 Starting Claude Code (no tool prompts)..."
    exec claude --dangerously-skip-permissions
elif [ "$1" = "claude-safe-no-prompts" ]; then
    echo "🤖 Starting Claude Code (safe tools only, no prompts)..."
    exec claude --allowedTools="Read,Write,Edit,Bash,Glob,Grep" --dangerously-skip-permissions
else
    exec "$@"
fi
