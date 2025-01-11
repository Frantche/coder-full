# Base image
FROM harbor.frantchenco.page/private-docker/ubuntu:noble-20241118.1

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Define versions as arguments for easy updates
ARG DOCKER_CE_VERSION=5:27.4.1-1~ubuntu.24.04~noble
ARG HASURA_CLI_VERSION=2.45.1
ARG NODE_VERSION=23.6.0
ARG NVM_VERSION=0.40.1
ARG YARN_VERSION=1.22.19
ARG GO_VERSION=1.21.4
ARG RUSTUP_VERSION=1.26.0

# Install dependencies and Docker
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        software-properties-common \
        lsb-release \
        bash \
        build-essential \
        git \
        htop \
        iproute2 \
        jq \
        locales \
        man \
        openssl \
        python3 \
        python3-pip \
        sudo \
        systemd \
        unzip \
        vim \
        wget \
        ssh \
        rsync && \
    update-ca-certificates && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-cache madison docker-ce | awk '{ print $3 }' && \
    apt-get install -y --no-install-recommends \
        containerd.io \
        docker-ce=$DOCKER_CE_VERSION \
        docker-ce-cli=$DOCKER_CE_VERSION \
        docker-buildx-plugin \
        docker-compose-plugin && \
    ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Locale settings
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Hasura CLI
RUN curl -L -o /usr/local/bin/hasura "https://github.com/hasura/graphql-engine/releases/download/v${HASURA_CLI_VERSION}/cli-hasura-linux-amd64" && \
    chmod +x /usr/local/bin/hasura

# Installer nvm et Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    export NVM_DIR="/root/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install v${NODE_VERSION} && \
    nvm use v${NODE_VERSION} && \
    nvm alias default v${NODE_VERSION}

# Ajouter nvm au PATH
ENV NVM_DIR="/root/.nvm"
ENV PATH="$NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH"

# Vérifier l'installation
RUN node --version && npm --version

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn=${YARN_VERSION}-1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN curl -L -o go${GO_VERSION}.linux-amd64.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Setup Go environment variables
ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$GOROOT/bin
ENV GOPATH=/home/coder/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$PATH:$GOBIN

# Install Rust
RUN wget -O rustup-init https://sh.rustup.rs && \
    chmod +x rustup-init && \
    ./rustup-init -y --default-toolchain ${RUSTUP_VERSION} && \
    rm rustup-init

# Rust environment variables
ENV RUSTUP_HOME=/home/coder/rustup
ENV CARGO_HOME=/home/coder/cargo
ENV PATH=$PATH:$CARGO_HOME/bin

# Create a non-root user "coder"
RUN userdel -r ubuntu && \
    useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# Switch to non-root user
USER coder
