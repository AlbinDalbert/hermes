ARG HERMES_BASE_IMAGE=nousresearch/hermes-agent:latest
FROM ${HERMES_BASE_IMAGE}

USER root

ARG KUBECTL_VERSION=v1.30.14
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gpg \
        iproute2 \
        jq \
        less \
        ripgrep \
        wget && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="${TARGETARCH:-}"; \
    if [ -z "${arch}" ]; then \
        case "$(uname -m)" in \
            aarch64|arm64) arch="arm64" ;; \
            x86_64|amd64) arch="amd64" ;; \
            *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
        esac; \
    fi; \
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"; \
    curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl.sha256"; \
    echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum -c -; \
    install -m 0755 /tmp/kubectl /usr/local/bin/kubectl; \
    rm -f /tmp/kubectl /tmp/kubectl.sha256; \
    kubectl version --client=true

COPY bin/git-credential-github-token /usr/local/bin/git-credential-github-token

RUN chmod 0755 /usr/local/bin/git-credential-github-token && \
    git config --system credential.https://github.com.helper github-token
