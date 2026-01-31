# Base image
FROM mirror.gcr.io/ubuntu:noble-20260113

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# renovate: datasource=apt depName=docker-ce packageName=docker-ce versioning=loose
ARG DOCKER_CE_VERSION=5:27.4.1-1~ubuntu.24.04~noble

# renovate: datasource=github-releases depName=graphql-engine packageName=hasura/graphql-engine versioning=semver
ARG HASURA_CLI_VERSION=2.48.10

# renovate: datasource=github-releases depName=node packageName=nodejs/node versioning=semver
ARG NODE_VERSION=25.5.0

# renovate: datasource=npm depName=yarn versioning=semver
ARG YARN_VERSION=1.22.22

# renovate: datasource=github-releases depName=go packageName=golang/go versioning=semver
ARG GO_VERSION=1.24.3

# renovate: datasource=github-releases depName=k9s packageName=derailed/k9s versioning=semver
ARG K9S_VERSION=0.50.18

# renovate: datasource=github-releases depName=helm packageName=helm/helm versioning=semver
ARG HELM_VERSION=4.1.0

# renovate: datasource=github-tags depName=kubernetes packageName=kubernetes/kubernetes versioning=semver
ARG KUBECTL_VERSION=1.35.0

# renovate: datasource=github-releases depName=get-next-version packageName=thenativeweb/get-next-version versioning=semver
ARG GNV_VERSION=2.7.1

# renovate: datasource=npm depName=@github/copilot packageName=@github/copilot versioning=semver
ARG COPILOT_CLI_VERSION=0.0.399

# renovate: datasource=npm depName=opencode-ai packageName=opencode-ai versioning=semver
ARG OPENCODE_AI_VERSION=1.1.45

# renovate: datasource=npm depName=@fission-ai/openspec packageName=@fission-ai/openspec versioning=semver
ARG OPENSPEC_VERSION=1.1.1

# renovate: datasource=github-tags depName=postgresql packageName=postgres/postgres versioning=semver
ARG POSTGRESQL_VERSION=18.1

# renovate: datasource=github-releases depName=ripgrep packageName=BurntSushi/ripgrep versioning=semver
ARG RIPGREP_VERSION=15.1.0

# renovate: datasource=github-releases depName=tilt packageName=tilt-dev/tilt versioning=semver
ARG TILT_VERSION=0.36.3

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

# Install PostgreSQL client from official PostgreSQL repository
RUN apt-get update && \
    install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-$(echo ${POSTGRESQL_VERSION} | cut -d. -f1) && \
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
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# install get-next-version
RUN curl -L -o get-next-version https://github.com/thenativeweb/get-next-version/releases/download/${GNV_VERSION}/get-next-version-linux-amd64 && \
    install -o root -g root -m 0755 get-next-version /usr/local/bin/get-next-version && \
    rm get-next-version

# Install ripgrep
RUN curl -L -o ripgrep.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    tar -xzf ripgrep.tar.gz && \
    install -o root -g root -m 0755 "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg" /usr/local/bin/rg && \
    rm -rf ripgrep.tar.gz "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl"

# Install Tilt
RUN curl -fsSL -o tilt.tar.gz "https://github.com/tilt-dev/tilt/releases/download/v${TILT_VERSION}/tilt.${TILT_VERSION}.linux.x86_64.tar.gz" && \
    tar -xzf tilt.tar.gz && \
    install -o root -g root -m 0755 tilt /usr/local/bin/tilt && \
    rm -rf tilt.tar.gz tilt

# Locale settings
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Hasura CLI
RUN curl -L -o /usr/local/bin/hasura "https://github.com/hasura/graphql-engine/releases/download/v${HASURA_CLI_VERSION}/cli-hasura-linux-amd64" && \
    chmod +x /usr/local/bin/hasura

# Install Node.js (exact version)
RUN curl -fsSL -o node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" && \
    tar -xJf node.tar.xz -C /usr/local --strip-components=1 && \
    rm node.tar.xz && \
    node --version && \
    npm --version

# Install GitHub Copilot CLI
RUN npm install -g @github/copilot@${COPILOT_CLI_VERSION}

# Install opencode-ai and openspec
RUN npm install -g opencode-ai@${OPENCODE_AI_VERSION} && \
    npm install -g @fission-ai/openspec@${OPENSPEC_VERSION}

# Install Yarn globally via npm
RUN npm install --global yarn@${YARN_VERSION} && \
    yarn --version

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

# Copy and set up entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to non-root user
USER coder

# Set entrypoint to start Docker daemon
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
