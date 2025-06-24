# Base image
FROM mirror.gcr.io/ubuntu:noble-20250404

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# renovate: datasource=apt depName=docker-ce packageName=docker-ce versioning=loose
ARG DOCKER_CE_VERSION=5:27.4.1-1~ubuntu.24.04~noble

# renovate: datasource=github-releases depName=graphql-engine packageName=hasura/graphql-engine versioning=semver
ARG HASURA_CLI_VERSION=2.48.1

# renovate: datasource=github-releases depName=node packageName=nodejs/node versioning=semver
ARG NODE_VERSION=24.2.0

# renovate: datasource=github-releases depName=nvm packageName=nvm-sh/nvm versioning=semver
ARG NVM_VERSION=0.40.3

# renovate: datasource=github-releases depName=yarn packageName=yarnpkg/yarn versioning=semver
ARG YARN_VERSION=1.22.22

# renovate: datasource=github-releases depName=go packageName=golang/go versioning=semver
ARG GO_VERSION=1.24.3

# renovate: datasource=github-releases depName=k9s packageName=derailed/k9s versioning=semver
ARG K9S_VERSION=0.50.6

# renovate: datasource=github-releases depName=helm packageName=helm/helm versioning=semver
ARG HELM_VERSION=3.18.3

# renovate: datasource=github-tags depName=kubernetes packageName=kubernetes/kubernetes versioning=semver
ARG KUBECTL_VERSION=1.33.2

# renovate: datasource=github-releases depName=get-next-version packageName=thenativeweb/get-next-version versioning=semver
ARG GNV_VERSION=2.6.3

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

# Install Helm
RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -xzf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf helm.tar.gz linux-amd64

# Install k9s
RUN wget -qO-  "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | tar -xz && \
    install -o root -g root -m 0755 k9s /usr/local/bin/k9s

# Install Kubectl
ARG KUBECTL_VERSION=1.30.1
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# install get-next-version
ARG GNV_VERSION=2.6.3
RUN curl -L -o get-next-version https://github.com/thenativeweb/get-next-version/releases/download/${GNV_VERSION}/get-next-version-linux-amd64 && \
    install -o root -g root -m 0755 get-next-version /usr/local/bin/get-next-version && \
    rm get-next-version

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

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

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
