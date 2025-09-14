# Multi-stage build for Claude Code Development Environment
# Stage 1: Build stage for tools that need compilation
FROM debian:bookworm-slim AS builder

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install build dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    ca-certificates \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for build
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer

# Create non-root user for building
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -l -u ${UID} -g ${USER} -d ${HOME} -s /bin/bash ${USER}

# Switch to non-root user
USER ${USER}

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Install mise in build stage
RUN curl https://mise.run | MISE_INSTALL_PATH=${HOME}/.local/bin/mise bash

# Stage 2: Runtime stage
FROM debian:bookworm-slim AS runtime

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer \
    WORKSPACE=/workspace \
    PATH="/home/developer/.local/bin:$PATH"

# Install runtime packages from Debian repositories
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
    bash \
    curl \
    ca-certificates \
    make \
    gcc \
    g++ \
    libc6-dev \
    libffi-dev \
    openssl \
    libssl-dev \
    zlib1g \
    zlib1g-dev \
    libbz2-dev \
    xz-utils \
    libsqlite3-dev \
    libreadline-dev \
    libncurses-dev \
    tzdata \
    sudo \
    passwd \
    gnupg \
    tcl-dev \
    tk-dev \
    libgdbm-dev \
    patch \
    binutils \
    git \
    # Ruby build dependencies
    autoconf \
    bison \
    libyaml-dev \
    libreadline6-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    libdb-dev \
    # Additional build tools for better compatibility
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p ${WORKSPACE}

# Create non-root user with sudo access
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${USER} -d ${HOME} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy mise from builder stage
COPY --from=builder --chown=${USER}:${USER} /home/developer/.local/bin/mise /home/developer/.local/bin/mise

# Copy entrypoint script to system directory and make it executable
COPY src/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Change ownership of everything to the developer user
RUN chown -R ${USER}:${USER} ${HOME} ${WORKSPACE}

# Switch to non-root user
USER ${USER}

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Set up mise and bash configuration
RUN echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc && \
    echo "eval \"\$(~/.local/bin/mise activate bash)\"" >> ${HOME}/.bashrc && \
    echo "export MAKEFLAGS=\"-j1\"" >> ${HOME}/.bashrc && \
    echo "export NODE_OPTIONS=\"--max-old-space-size=4096\"" >> ${HOME}/.bashrc && \
    echo "export RUBY_CONFIGURE_OPTS=\"--with-jemalloc\"" >> ${HOME}/.bashrc && \
    echo "export RUBY_CFLAGS=\"-O3\"" >> ${HOME}/.bashrc

# Initialize GPG with proper configuration (simplified approach)
RUN mkdir -p ${HOME}/.gnupg && \
    chmod 700 ${HOME}/.gnupg && \
    echo "keyserver hkps://keys.openpgp.org" > ${HOME}/.gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" >> ${HOME}/.gnupg/gpg.conf && \
    echo "trust-model always" >> ${HOME}/.gnupg/gpg.conf && \
    gpg --list-keys || true

# Install Node.js via mise and then install Claude Code CLI
RUN eval "$(~/.local/bin/mise activate bash)" && \
    mise install node@24 && \
    mise global node@24 && \
    npm install -g @anthropic-ai/claude-code && \
    claude --version || echo "Claude Code installed but may need authentication"


# Set working directory
WORKDIR ${WORKSPACE}

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD eval "$(~/.local/bin/mise activate bash)" && claude --version || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
