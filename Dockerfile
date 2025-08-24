# Use Alpine Linux for minimal footprint
FROM alpine:3.22

# Set environment variables
ENV USER=developer \
    UID=1000 \
    GID=1000 \
    HOME=/home/developer \
    WORKSPACE=/workspace

# Install essential packages
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    tzdata \
    sudo \
    shadow \
    openssl \
    build-base \
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

# Install mise as the developer user
RUN curl https://mise.run | MISE_INSTALL_PATH=${HOME}/.local/bin/mise bash && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${HOME}/.bashrc && \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ${HOME}/.bashrc

# Install Claude Code as the developer user
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${HOME}/.bashrc
WORKDIR ${WORKSPACE}

# Set entrypoint
ENTRYPOINT ["/home/developer/entrypoint.sh"]
