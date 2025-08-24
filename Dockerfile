# Multi-stage build for Claude Code Development Environment
# Stage 1: Build stage for tools that need compilation
FROM alpine:3.22 AS builder

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install build dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    build-base \
    git \
    && rm -rf /var/cache/apk/*

# Set environment variables for build
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer

# Create non-root user for building
RUN addgroup -g ${GID} ${USER} && \
    adduser -D -u ${UID} -G ${USER} -h ${HOME} -s /bin/bash ${USER}

# Switch to non-root user
USER ${USER}

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Install mise in build stage
RUN curl https://mise.run | MISE_INSTALL_PATH=${HOME}/.local/bin/mise bash

# Stage 2: Runtime stage
FROM alpine:3.22 AS runtime

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Set environment variables
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer \
    WORKSPACE=/workspace \
    PATH="/home/developer/.local/bin:$PATH"

# Install runtime packages from Alpine repositories
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    make \
    gcc \
    g++ \
    musl-dev \
    libffi-dev \
    openssl \
    openssl-dev \
    zlib \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    sqlite-dev \
    readline-dev \
    ncurses-dev \
    tzdata \
    sudo \
    shadow \
    gnupg \
    tcl-dev \
    tk-dev \
    gdbm-dev \
    fortify-headers \
    patch \
    binutils \
    && rm -rf /var/cache/apk/*

# Add edge repositories for latest packages
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --upgrade --no-cache \
    busybox \
    git \
    ssl_client \
    && rm -rf /var/cache/apk/*

# Create workspace directory
RUN mkdir -p ${WORKSPACE}

# Create non-root user with sudo access
RUN addgroup -g ${GID} ${USER} && \
    adduser -D -u ${UID} -G ${USER} -h ${HOME} -s /bin/bash ${USER} && \
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
    echo "export NODE_OPTIONS=\"--max-old-space-size=4096\"" >> ${HOME}/.bashrc

# Initialize GPG with proper configuration (simplified approach)
RUN mkdir -p ${HOME}/.gnupg && \
    chmod 700 ${HOME}/.gnupg && \
    echo "keyserver hkps://keys.openpgp.org" > ${HOME}/.gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" >> ${HOME}/.gnupg/gpg.conf && \
    echo "trust-model always" >> ${HOME}/.gnupg/gpg.conf && \
    gpg --list-keys || true

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc

# Set working directory
WORKDIR ${WORKSPACE}

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD claude --version || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
