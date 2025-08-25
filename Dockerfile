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

# Install essential packages from stable repo
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    tzdata \
    sudo \
    shadow \
    openssl \
    make \
    patch \
    fortify-headers \
    gcc \
    g++ \
    musl-dev \
    libstdc++-dev \
    binutils \
    && rm -rf /var/cache/apk/*

# Add edge repositories and upgrade specific vulnerable packages
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --upgrade --no-cache \
    git \
    linux-pam \
    busybox \
    ssl_client \
    busybox-binsh \
    && rm -rf /var/cache/apk/*

# Create workspace directory
RUN mkdir -p ${WORKSPACE}

# Create non-root user with sudo access
RUN addgroup -g ${GID} ${USER} && \
    adduser -D -u ${UID} -G ${USER} -h ${HOME} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy entrypoint script and make it executable
COPY entrypoint.sh /home/developer/entrypoint.sh
RUN chmod +x /home/developer/entrypoint.sh

# Change ownership of everything to the developer user
RUN chown -R ${USER}:${USER} ${HOME} ${WORKSPACE}

# Switch to non-root user
USER ${USER}

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Install mise and Claude Code as the developer user
RUN curl https://mise.run | MISE_INSTALL_PATH=${HOME}/.local/bin/mise bash && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc && \
    echo "eval \"\$(~/.local/bin/mise activate bash)\"" >> ${HOME}/.bashrc && \
    curl -fsSL https://claude.ai/install.sh | bash && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ${HOME}/.bashrc
WORKDIR ${WORKSPACE}


# Set entrypoint
ENTRYPOINT ["/home/developer/entrypoint.sh"]
