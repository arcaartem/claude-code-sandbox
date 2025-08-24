# Claude Code Development Environment - Project Context

## Project Overview

I've created a lightweight Docker image specifically for running Claude Code in a secure sandbox environment. This allows for safe AI-assisted development that can't affect the host system while providing access to project files through volume mounting.

## What We've Built

### Core Components

1. **Dockerfile** - Alpine Linux 3.22 based container with:
   - Non-root user (`developer`, UID 1000) 
   - mise (universal tool version manager)
   - Claude Code (AI coding assistant)
   - Essential dev tools (git, curl, bash, build-base, openssl)

2. **entrypoint.sh** - Simplified startup script that:
   - Sets up PATH for user binaries
   - Auto-detects `.mise.toml` and installs programming languages
   - Starts Claude Code by default
   - No fallbacks - Claude Code must work or container fails

3. **Security & CI Setup** - GitHub Actions workflows for:
   - Comprehensive security scanning (Trivy, Grype, Docker Scout, Hadolint, Checkov)
   - Automated CI testing
   - Dependabot for dependency updates

### Key Design Decisions

- **Single purpose**: Focused solely on Claude Code, no fallback to bash
- **Security first**: Non-root user, minimal attack surface, isolated sandbox
- **Portable**: Can be invoked from any project directory
- **Auto-setup**: Detects `.mise.toml` and installs required programming languages
- **Latest versions**: Alpine 3.22, latest mise and Claude Code

## How It Works

### Basic Usage
```bash
# Build the image once
docker build -t devenv .

# Use in any project
cd /path/to/your/project
docker run -it --rm -v $(pwd):/workspace -p 3000:3000 devenv
```

### With Convenient Alias
```bash
alias devenv='docker run -it --rm -v $(pwd):/workspace -p 3000:3000 devenv'
cd my-project
devenv  # Starts Claude Code with project mounted
```

## Project Structure Created

```
repository/
├── .github/
│   ├── workflows/
│   │   ├── security-scan.yml    # Full security scanning
│   │   └── ci.yml              # CI with Claude Code testing
│   └── dependabot.yml          # Dependency updates
├── Dockerfile                  # Alpine 3.22 + mise + Claude Code
├── entrypoint.sh              # Startup script (no fallbacks)
├── README.md                  # Complete documentation
├── LICENSE                    # MIT license
└── agent.md                   # This context file
```

## Technical Details

### Exposed Ports
- `3000` - React, Next.js, Node.js frameworks
- `8000` - Django, Python HTTP servers
- `8080` - Alternative HTTP, Java apps, webpack dev server
- `5000` - Flask, Node.js apps
- `9000` - PHP-FPM, development tools

### Volume Mounts
- Current directory → `/workspace` (where Claude Code operates)
- Optional: `mise-cache` volume for faster tool installations

### Environment Variables
- `USER=developer`
- `UID=1000`
- `HOME=/home/developer`
- `WORKSPACE=/workspace`

## Programming Language Support via mise

The container auto-detects `.mise.toml` files and installs specified tools. Examples:

### Node.js Project
```toml
[tools]
node = "20"
npm = "latest"
```

### Python Project  
```toml
[tools]
python = "3.11"
poetry = "latest"
```

### Multi-language Project
```toml
[tools]
node = "20"
python = "3.11" 
go = "1.21"
rust = "1.75"
```

## Security Features

- **Automated scanning**: Every push/PR triggers security scans
- **Multiple scanners**: Trivy, Grype, Docker Scout, Hadolint, Checkov
- **Results integration**: Uploaded to GitHub Security tab
- **Weekly scans**: Scheduled vulnerability checks
- **Minimal base**: Alpine Linux reduces attack surface
- **Isolation**: Container can't affect host system

## Issues Encountered & Resolved

1. **Permission errors**: Fixed by doing all installation as root, then changing ownership
2. **Complex shell escaping**: Resolved by using separate shell script instead of inline commands
3. **Claude Code PATH issues**: Fixed by explicit PATH setup in entrypoint
4. **Fallback complexity**: Simplified to single-purpose container (Claude Code only)

## Current Status

✅ **Working**: Container builds successfully  
✅ **Tested**: CI verifies Claude Code installation and functionality  
✅ **Documented**: Complete README with examples and security info  
✅ **Secured**: Comprehensive automated security scanning setup  
⏳ **Ready for**: Claude Code session in sandbox environment  

## Next Steps for Claude Code Session

1. Copy this context to your project
2. Build the Docker image: `docker build -t devenv .`
3. Run in your project: `devenv` (with alias) or full docker command
4. Claude Code will have access to:
   - This context file for understanding the project
   - All project files in `/workspace`
   - Ability to install any programming languages via mise
   - Isolated, secure environment for development

## Goals Achieved

- ✅ Lightweight container (~80MB)
- ✅ Secure sandbox environment  
- ✅ Claude Code ready-to-use
- ✅ Flexible language support via mise
- ✅ Professional GitHub repository setup
- ✅ Comprehensive security scanning
- ✅ Single-command usage from any project
- ✅ Auto-setup with `.mise.toml` detection

The container is designed to be your go-to tool for safe AI-assisted development with Claude Code, providing isolation while maintaining full access to your project files.
