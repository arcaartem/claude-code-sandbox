# Use Alpine Linux for minimal footprint
FROM alpine:3.22

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Set environment variables
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer \
    WORKSPACE=/workspace

# Install essential packages from stable repo including SSL and compression libraries
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    tzdata \
    sudo \
    shadow \
    openssl \
    openssl-dev \
    make \
    patch \
    fortify-headers \
    gcc \
    g++ \
    musl-dev \
    libstdc++-dev \
    binutils \
    zlib \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    libffi-dev \
    sqlite-dev \
    ncurses-dev \
    readline-dev \
    gdbm-dev \
    tk-dev \
    tcl-dev \
    && rm -rf /var/cache/apk/*

# Add edge repositories and upgrade specific vulnerable packages, install GPG from edge
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --upgrade --no-cache \
    git \
    linux-pam \
    busybox \
    ssl_client \
    busybox-binsh \
    gnupg \
    && rm -rf /var/cache/apk/*

# Create workspace directory
RUN mkdir -p ${WORKSPACE}

# Create non-root user with sudo access
RUN addgroup -g ${GID} ${USER} && \
    adduser -D -u ${UID} -G ${USER} -h ${HOME} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy entrypoint script to system directory and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Change ownership of everything to the developer user
RUN chown -R ${USER}:${USER} ${HOME} ${WORKSPACE}

# Switch to non-root user
USER ${USER}

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Install mise and Claude Code as the developer user, then install Python
# Initialize fresh GPG keyring to avoid database corruption issues
RUN curl https://mise.run | MISE_INSTALL_PATH=${HOME}/.local/bin/mise bash && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc && \
    echo "eval \"\$(~/.local/bin/mise activate bash)\"" >> ${HOME}/.bashrc && \
    export PATH="${HOME}/.local/bin:$PATH" && \
    rm -rf ${HOME}/.gnupg && \
    gpg --list-keys && \
    ~/.local/bin/mise install python@latest && \
    ~/.local/bin/mise use python@latest -g && \
    curl -fsSL https://claude.ai/install.sh | bash && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc
WORKDIR ${WORKSPACE}


# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
