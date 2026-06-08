# vi: ft=dockerfile
# Auto-generated via Ansible: edit .ansible/DOCKERFILES/Dockerfile-work.j2 instead.

# Work stage layers on top of the previously published base image
# (devilboxcommunity/agentic:base). Matches the docker-php-fpm
# convention where higher-tier stages FROM the lower-tier published image
# rather than re-implementing it inline.
#
# The work image adds:
#   - ALL runtimes: nvm + Node LTS, Go, Bun, Python + pip/venv/pipx + uv
#   - ALL comfort/dev tools: jq, yq, rg, fd, gh, tmux, vim, etc.
#   - Build toolchain: gcc, g++, cmake, *-dev packages
#   - Extra tools: openspec, speckit
#   - bash-devilbox + sudo configuration
FROM devilboxcommunity/agentic:base AS work

###
### Labels
###
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#LABEL "org.opencontainers.image.created"=""
#LABEL "org.opencontainers.image.version"=""
#LABEL "org.opencontainers.image.revision"=""
LABEL "maintainer"="Toan Nguyen <devilbox@nntoan.com>"
LABEL "org.opencontainers.image.authors"="Toan Nguyen <devilbox@nntoan.com>"
LABEL "org.opencontainers.image.url"="https://github.com/devilbox-community/docker-agentic"
LABEL "org.opencontainers.image.documentation"="https://github.com/devilbox-community/docker-agentic"
LABEL "org.opencontainers.image.source"="https://github.com/devilbox-community/docker-agentic"
LABEL "org.opencontainers.image.vendor"="Devilbox Community"
LABEL "org.opencontainers.image.licenses"="MIT"
LABEL "org.opencontainers.image.ref.name"="work"
LABEL "org.opencontainers.image.title"="Devilbox Agentic (work)"
LABEL "org.opencontainers.image.description"="Devilbox container shipping agentic coding CLIs (work stage)"

ARG GO_VERSION=1.23.4
ARG TARGETARCH

ENV PATH=/opt/nvm/current/bin:/home/devilbox/go/bin:/usr/local/go/bin:/home/devilbox/.local/bin:${PATH}

USER root

###
### Install developer comfort tools + gh CLI + pipx + python (was in base)
###
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        bash-completion \
        bzip2 \
        direnv \
        dnsutils \
        fd-find \
        gh \
        htop \
        iputils-ping \
        jq \
        nano \
        netcat-openbsd \
        openssh-client \
        pipx \
        procps \
        psmisc \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        socat \
        tmux \
        tree \
        unzip \
        vim \
        xz-utils \
        yq \
        zip \
    && curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

###
### Install build toolchain (gcc, *-dev) and system dev packages
###
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        build-essential \
        cmake \
        g++ \
        gcc \
        libffi-dev \
        libssl-dev \
        make \
        pkg-config \
        python3-dev \
    && rm -rf /var/lib/apt/lists/*

###
### Install Go
###
RUN set -eux \
    && case "${TARGETARCH:-amd64}" in \
        amd64) go_arch="amd64" ;; \
        arm64) go_arch="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o /tmp/go.tgz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm -f /tmp/go.tgz

###
### Install nvm + Node LTS
###
ENV NVM_DIR=/opt/nvm
ENV NVM_VERSION=v0.40.4
ENV NODE_VERSION=lts/*

RUN set -eux \
    && install -d -m 0755 /opt/nvm \
    && curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
       | NVM_DIR=/opt/nvm PROFILE=/dev/null bash \
    && chown -R devilbox:devilbox /opt/nvm \
    && su -s /bin/bash -c '. /opt/nvm/nvm.sh && nvm install "'"${NODE_VERSION}"'" && nvm alias default "'"${NODE_VERSION}"'"' devilbox \
    && NODE_DIR="$(su -s /bin/bash -c '. /opt/nvm/nvm.sh && nvm which default | xargs dirname' devilbox)" \
    && ln -sfn "$(dirname ${NODE_DIR})" /opt/nvm/current \
    && for bin in node npm npx corepack; do \
         [ -f "${NODE_DIR}/${bin}" ] && ln -sf "${NODE_DIR}/${bin}" "/usr/local/bin/${bin}"; \
       done \
    && /usr/local/bin/corepack enable \
    && node --version && npm --version

RUN set -eux \
    && NODE_BIN="$(su -s /bin/bash -c '. /opt/nvm/nvm.sh && nvm which default | xargs dirname' devilbox)" \
    && echo "export PATH=\"${NODE_BIN}:\$PATH\"" > /etc/profile.d/nvm-path.sh \
    && echo "PATH=\"${NODE_BIN}:${PATH}\"" >> /etc/environment

###
### Install bun
###
ENV BUN_VERSION=latest
RUN set -eux \
    && curl -fsSL https://bun.sh/install | bash \
    && install -m 0755 /root/.bun/bin/bun /usr/local/bin/bun \
    && (install -m 0755 /root/.bun/bin/bunx /usr/local/bin/bunx 2>/dev/null || ln -sf /usr/local/bin/bun /usr/local/bin/bunx) \
    && rm -rf /root/.bun \
    && bun --version

###
### Install extra tools (openspec, speckit) from extra_tools/
###


# -------------------- openspec --------------------
RUN set -eux; \
	npm install -g @fission-ai/openspec@latest; \
	npm cache clean --force; \
	mkdir -p /opt/agentic-tools/openspec/bin; \
	install -m 0755 "$(command -v openspec)" /opt/agentic-tools/openspec/bin/openspec; \
	mkdir -p /opt/agentic-tools/openspec/bin; \
	if [ ! -x /opt/agentic-tools/openspec/bin/openspec ] && command -v openspec >/dev/null 2>&1; then \
		install -m 0755 "$(command -v openspec)" /opt/agentic-tools/openspec/bin/openspec; \
	fi; \
	true
# -------------------- speckit --------------------
RUN set -eux; \
	pipx install specify-cli; \
	pip cache purge; \
	mkdir -p /opt/agentic-tools/speckit/bin; \
	install -m 0755 /root/.local/bin/specify /opt/agentic-tools/speckit/bin/specify; \
	chmod -R a+rx /root; \
	mkdir -p /opt/agentic-tools/speckit/bin; \
	if [ ! -x /opt/agentic-tools/speckit/bin/specify ] && command -v specify >/dev/null 2>&1; then \
		install -m 0755 "$(command -v specify)" /opt/agentic-tools/speckit/bin/specify; \
	fi; \
	true


# ----- Default-enabled extra tools (symlinked to /usr/local/bin/ at build time): -----
# openspec  (openspec)
# speckit  (specify)
# ----- Installed-only extra tools (binary exists, no PATH symlink by default): -----

RUN set -eux \
    && ln -sfn /opt/agentic-tools/openspec/bin/openspec /usr/local/bin/openspec \
    && ln -sfn /opt/agentic-tools/speckit/bin/specify /usr/local/bin/specify \
    && true

COPY ./data/bash-devilbox /etc/bash-devilbox
COPY ./data/sudo-devilbox /etc/sudoers.d/devilbox

RUN set -eux \
    && chmod 0440 /etc/sudoers.d/devilbox \
    && echo ". /etc/bash-devilbox" >> /root/.bashrc \
    && echo ". /etc/bash-devilbox" >> /home/devilbox/.bashrc \
    && { \
        echo; \
        echo "# [Devilbox] Ensure go, node, npm, npx, bun are in PATH"; \
        echo 'PATH="/usr/local/go/bin:${PATH}"'; \
        echo 'PATH="/opt/nvm/current/bin:${PATH}"'; \
        echo 'PATH="${HOME}/go/bin:${PATH}"'; \
        echo "export PATH"; \
        echo; \
        echo "# [Devilbox] Ensure to load nvm"; \
        echo 'export NVM_DIR="/opt/nvm"'; \
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'; \
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'; \
    } | tee -a /home/devilbox/.bashrc /root/.bashrc \
    && chown devilbox:devilbox /home/devilbox/.bashrc

WORKDIR /shared/httpd

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
CMD ["bash"]
