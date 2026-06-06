# vi: ft=dockerfile
# Auto-generated via Ansible: edit .ansible/DOCKERFILES/Dockerfile-work.j2 instead.

# Work stage layers on top of the previously published base image
# (devilboxcommunity/agentic:base). Matches the docker-php-fpm
# convention where higher-tier stages FROM the lower-tier published image
# rather than re-implementing it inline.
# The work image adds the build toolchain (gcc, *-dev packages) and extra
# tools (openspec, speckit), mirroring docker-php-fpm's slim + work stages.
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

USER root

###
### Install build toolchain (gcc, *-dev) and system tools
###
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        bash-completion \
        build-essential \
        cmake \
        g++ \
        gcc \
        libffi-dev \
        libssl-dev \
        make \
        pkg-config \
        python3-dev \
        sudo \
    && rm -rf /var/lib/apt/lists/*

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
    && chown devilbox:devilbox /home/devilbox/.bashrc

USER devilbox
WORKDIR /shared/httpd

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
CMD ["bash"]
