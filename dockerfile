# Base image
FROM harbor.frantchenco.page/private-docker/ubuntu:noble-20241118.1

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Define versions as arguments for easy updates
ARG DOCKER_CE_VERSION=24.0.5
ARG HASURA_CLI_VERSION=2.45.1
ARG NODE_VERSION=18.17.1
ARG NVM_VERSION=0.39.3
ARG YARN_VERSION=1.22.19
ARG GO_VERSION=1.21.4
ARG RUSTUP_VERSION=1.26.0

# Install the Docker apt repository
RUN apt-get update && \
    apt-get upgrade --yes --no-install-recommends --no-install-suggests && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    ca-certificates curl software-properties-common && \
    update-ca-certificates && \
    install -m 0755 -d /etc/apt/keyrings && \
    add-apt-repository ppa:git-core/ppa && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    bash \
    build-essential \
    ca-certificates \
    containerd.io \
    docker-ce=$DOCKER_CE_VERSION* \
    docker-ce-cli=$DOCKER_CE_VERSION* \
    docker-buildx-plugin \
    docker-compose-plugin \
    git \
    htop \
    iproute2 \
    jq \
    locales \
    man \
    openssl \
    pipx \
    python3 \
    python3-pip \
    sudo \
    systemd \
    systemd-sysv \
    unzip \
    vim \
    wget \
    rsync && \
    rm -rf /var/lib/apt/lists/*

# Enables Docker starting with systemd
RUN systemctl enable docker

# Create a symlink for standalone docker-compose usage
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN pipx ensurepath # adds users bin directory to PATH

# Install Hasura CLI
RUN curl --tlsv1.3 -L -o /usr/local/bin/hasura https://github.com/hasura/graphql-engine/releases/download/v${HASURA_CLI_VERSION}/cli-hasura-linux-amd64 && \
    chmod +x /usr/local/bin/hasura

# Install Node.js via NVM
RUN curl --tlsv1.3 -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    source ~/.bashrc && \
    nvm install ${NODE_VERSION} && \
    nvm alias default ${NODE_VERSION}

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn=${YARN_VERSION}-1

# Install Go
RUN curl -L -o go${GO_VERSION}.linux-amd64.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Setup Go environment variables
ENV GOROOT /usr/local/go
ENV PATH $PATH:$GOROOT/bin
ENV GOPATH /home/coder/go
ENV GOBIN $GOPATH/bin
ENV PATH $PATH:$GOBIN

# Set Rust environment variables
ENV RUSTUP_HOME=/home/coder/rustup
ENV CARGO_HOME=/home/coder/cargo
ENV PATH $PATH:$CARGO_HOME/bin

# Install Rust
RUN wget -O rustup-init https://sh.rustup.rs && chmod +x rustup-init && ./rustup-init -y --default-toolchain ${RUSTUP_VERSION} && rm rustup-init

# Remove the `ubuntu` user and add a user `coder` so that you're not developing as the `root` user
RUN userdel -r ubuntu && \
    useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder
