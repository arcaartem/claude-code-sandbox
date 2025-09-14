#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Set up PATH and activate mise
export PATH="$HOME/.local/bin:$PATH"
eval "$(~/.local/bin/mise activate bash)"

# Change to workspace directory
cd /workspace

log "🚀 Development environment ready!"
log "📁 Working directory: $(pwd)"
log "🛠️  Available tools: mise, claude"
log ""

# Auto-detect and setup mise tools if .mise.toml exists
if [ -f ".mise.toml" ]; then
    log "📋 Found .mise.toml, installing tools..."
    if mise install; then
        log "✅ Tools installed successfully!"
    else
        log "⚠️  Some tools failed to install, continuing anyway..."
    fi
    log ""
fi

# Start Claude Code by default, or run specified command
if [ "$#" -eq 0 ] || [ "$1" = "claude" ]; then
    log "🤖 Starting Claude Code..."
    exec claude
elif [ "$1" = "claude-no-prompts" ]; then
    log "🤖 Starting Claude Code (no tool prompts)..."
    exec claude --dangerously-skip-permissions
elif [ "$1" = "claude-safe-no-prompts" ]; then
    log "🤖 Starting Claude Code (safe tools only, no prompts)..."
    exec claude --allowedTools="Read,Write,Edit,Bash,Glob,Grep" --dangerously-skip-permissions
else
    log "🔧 Executing custom command: $*"
    exec "$@"
fi
