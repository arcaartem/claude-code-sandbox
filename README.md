# Claude Code Development Environment

A lightweight, secure Docker image for running **Claude Code** in an isolated sandbox environment with **mise** for programming language management. Perfect for safe AI-assisted development that can't affect your host system.

## Why This Project?

This project provides a secure, isolated Docker environment specifically designed for AI-assisted development with Claude Code. It prevents AI tools from accidentally affecting your host system while maintaining full access to your project files.

## 🚀 Quick Start

```bash
# Build the image
git clone https://github.com/yourusername/claude-code-sandbox.git
cd claude-code-sandbox
docker build -t devenv .

# Set up aliases (add to ~/.bashrc or ~/.zshrc)
alias devenv='docker run -it --rm -v $(pwd):/workspace -v claude-container-config:/home/developer -v mise-cache:/home/developer/.local/share/mise devenv'

# Use in any project
cd /path/to/your/project
devenv
```

## ✨ Features

- **🐧 Lightweight**: Alpine Linux 3.22 base (~80MB total image size)
- **🤖 Claude Code Ready**: Pre-installed and ready to assist with development
- **🛠️ Language Flexibility**: Use mise to install any programming language
- **🔒 Safe Isolation**: Runs in container, can't affect your host system
- **📁 Direct Access**: Current directory mounted as `/workspace`
- **🎯 Portable**: Same command works in any project directory

## 📋 What's Included

- **Alpine Linux 3.22** - Latest stable, secure base
- **mise** - Universal tool version manager (latest version)
- **Claude Code** - AI-powered coding assistant (latest version)
- **Development essentials**: git, curl, bash, build-base, openssl
- **Non-root user** - Secure by default (`developer` user, UID 1000)

## 🏃 Usage

### Create a Convenient Alias
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# With Claude config in named volume (persistent settings)
alias devenv='docker run -it --rm -v $(pwd):/workspace -v claude-container-config:/home/developer -v mise-cache:/home/developer/.local/share/mise devenv'

# No-prompts version (all tools allowed, no confirmations)
alias devenv-auto='docker run -it --rm -v $(pwd):/workspace -v claude-container-config:/home/developer -v mise-cache:/home/developer/.local/share/mise devenv claude-no-prompts'

# Safe no-prompts version (limited tools, no confirmations)
alias devenv-safe='docker run -it --rm -v $(pwd):/workspace -v claude-container-config:/home/developer -v mise-cache:/home/developer/.local/share/mise devenv claude-safe-no-prompts'

# Bash shell access
alias devenv-bash='docker run -it --rm -v $(pwd):/workspace -v claude-container-config:/home/developer -v mise-cache:/home/developer/.local/share/mise devenv bash'
```

Then simply:
```bash
cd my-project
devenv            # Starts Claude Code (with tool prompts)
devenv-auto       # Starts Claude Code (no tool prompts, all tools)
devenv-safe       # Starts Claude Code (no prompts, safe tools only)
devenv-bash       # Starts bash shell
```

## 🎛️ Auto-Setup with mise

Create a `.mise.toml` in your project root to automatically install tools:

```toml
[tools]
node = "20"
python = "3.11"
go = "1.21"

[env]
NODE_ENV = "development"

[tasks.dev]
run = "npm run dev"
description = "Start development server"
```

The container will detect this file and install all specified tools automatically.

## 📖 Example Workflows

### Node.js Development
```bash
cd my-node-app
echo '[tools]\nnode = "20"' > .mise.toml
devenv  # Claude Code starts with Node.js 20 ready
```

### Python Development
```bash
cd my-python-project
echo '[tools]\npython = "3.11"' > .mise.toml
devenv  # Claude Code starts with Python 3.11 ready
```

### Multi-Language Project
```bash
cd my-fullstack-app
cat > .mise.toml << EOF
[tools]
node = "20"
python = "3.11"
go = "1.21"
rust = "1.75"
EOF
devenv  # All languages available
```

## 🔐 First-Time Setup

On first run, Claude Code will prompt you to authenticate:

```bash
cd your-project
devenv  # Will prompt for Claude Code setup
```

Choose your authentication method:
- **Pro subscription** (recommended): Follow prompts to authenticate
- **API key**: Provide your Anthropic API key when prompted

Settings are saved in the `claude-container-config` volume and persist between runs.

## 🔧 Customization

### Environment Variables
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v claude-container-config:/home/developer \
  -v mise-cache:/home/developer/.local/share/mise \
  -e NODE_ENV=development \
  -e DEBUG=true \
  devenv
```

### Claude Code Configuration

**Authentication options:**

1. **Named Volume** (Recommended): Persistent container-specific config
   ```bash
   -v claude-container-config:/home/developer
   ```
   Settings persist between container runs and are separate from host.

2. **Environment Variable**: Set your API key directly
   ```bash
   -e ANTHROPIC_API_KEY=your_api_key_here
   ```

3. **Host Config Mount**: Share your host Claude config (may cause conflicts)
   ```bash
   -v ~/.claude.json:/home/developer/.claude.json -v ~/.claude:/home/developer/.claude
   ```

**Tool Permission Modes:**

- **Default Mode**: Prompts for permission before using tools (`devenv`)
- **No Prompts Mode**: All tools allowed without confirmation (`devenv-auto`) - **Use with caution**
- **Safe Mode**: Limited to safe tools only (`devenv-safe`)


## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related

- [mise](https://mise.jdx.dev/) - Tool version manager
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - AI-powered coding assistant
- [Alpine Linux](https://alpinelinux.org/) - Lightweight Linux distribution
