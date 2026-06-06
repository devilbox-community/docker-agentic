# docker-php-fpm Multi-Stage Deep Dive — Stage-by-Stage Analysis

## Date: 2026-06-05

---

## docker-php-fpm Stage Chain (exact FROM lines)

```
Dockerfile-base.j2:  FROM debian:${DEBIAN_VERSION} AS base
Dockerfile-mods.j2:  FROM ${docker_user}/php-fpm:${php_version}-base AS mods-builder
                     FROM ${docker_user}/php-fpm:${php_version}-base AS mods
Dockerfile-prod.j2:  FROM ${docker_user}/php-fpm:${php_version}-mods AS prod
Dockerfile-slim.j2:  FROM ${docker_user}/php-fpm:${php_version}-prod AS slim
Dockerfile-work.j2:  FROM ${docker_user}/php-fpm:${php_version}-slim AS devilbox-work-help-builder
                     FROM ${docker_user}/php-fpm:${php_version}-slim AS devilbox-work-help
                     ... 7 total stages within work
```

Key insight: Each Dockerfile produces a PUBLISHED image. They FROM the previously
published image, NOT a local stage alias. This is critical for CI — you can
build mods without rebuilding base, because mods FROMs the published base image
on Docker Hub.

---

## The BUILDER → COPY pattern (why it saves space)

### In docker-php-fpm's mods stage:

```
Stage 1: mods-builder
  FROM base
  apt-get install build-essential, *-dev packages   ← 300MB of build tools
  pecl install / phpize / make                       ← compiles .so files

Stage 2: mods
  FROM base                                          ← fresh FROM, no build tools
  COPY --from=mods-builder /usr/local/lib/php/extensions/   ← only .so files
```

Result: The mods image is base + .so files (~5-10MB). The 300MB of build tools
stay in the builder image (not pushed, not saved).

### In docker-php-fpm's work stage:

```
Stage 1: work-help-builder
  FROM slim
  apt-get install composer, pip, rubygem build_dep   ← build tools
  composer global require ...                         ← builds packages
  pip install ...                                     ← builds packages
  gem install ...                                     ← builds packages

Stage 2: work-help
  FROM slim                                          ← fresh FROM
  COPY --from=builder /usr/local/bin                  ← only binaries
  COPY --from=builder /usr/local/lib                  ← only libraries
  COPY --from=builder /opt/nvm                        ← only nvm
```

---

## HOW THIS APPLIES TO docker-agentic

### What we have now:

```
Dockerfile-base.j2:  FROM debian:trixie-slim AS base   ← single stage, all inline
Dockerfile-work.j2:  FROM base AS work                  ← single stage
Dockerfile-agentic.j2: FROM work AS agentic-builder     ← builder stage
                       FROM work AS {tool}              ← final stage
                       COPY --from=builder ...          ← correct pattern
```

### What we SHOULD have (docker-php-fpm pattern):

The base image should ALSO use a builder pattern for installing toolchain:

```
Stage 1: base-builder
  FROM debian:trixie-slim
  apt-get install build-essential, *-dev  ← build deps for Go/Node/Python/bun?
  Install Go (from source? No — pre-built binary)
  Install nvm + Node (pre-built)
  Install bun (pre-built)
  Install uv (pre-built)
  Install agentic_tools (openspec, speckit) with their build_dep

Stage 2: base
  FROM debian:trixie-slim                  ← fresh FROM, no build tools
  COPY --from=base-builder /usr/local/go   ← Go runtime only
  COPY --from=base-builder /opt/nvm        ← Node runtime only
  COPY --from=base-builder /usr/local/bin  ← bun, uv, tool binaries
  COPY --from=base-builder /opt/agentic-tools  ← tool binaries
  apt-get install run_dep only             ← runtime deps (git, curl, etc.)
```

But wait — Go, Node, and Bun are installed from pre-built binaries. They don't
need build-essential. The only thing that needs build tools is pipx (if a wheel
isn't available) and npm (if a native addon needs compilation).

### The realistic optimization:

Since Go/Node/Bun are pre-built, and pipx/npm rarely need compilation, the
biggest win is simply REMOVING build toolchain from the base image's apt-get
install list. We already did this (removed build-essential, gcc, g++, cmake,
libffi-dev, libssl-dev, python3-dev, pkg-config, make from base).

### Additional optimization: builder stage for agentic_tools

The base image installs agentic_tools (openspec, speckit) inline. If we add
a builder stage, npm and pipx would run in the builder (with their caches),
and only the binaries would be copied to the final image.

But for just 2 small tools (openspec ~5MB, speckit ~2MB), the overhead of
a builder stage might not be worth it.

### The per-agent images already use the correct pattern:

```
agentic-builder: installs tool (with build_dep, npm cache, pip cache)
{tool}:          FROM work, COPY only binary from builder
```

This is correct and matches docker-php-fpm.

---

## SIZE COMPARISON (estimated)

| Component | Before | After (estimated) |
|-----------|--------|-------------------|
| Debian slim base | ~80MB | ~80MB |
| System tools (git, curl, jq, etc.) | ~200MB | ~200MB |
| Build toolchain (gcc, *-dev) | ~250MB | 0MB (removed) |
| Go | ~150MB | ~150MB |
| Node (nvm + LTS) | ~200MB | ~200MB |
| Bun | ~100MB | ~100MB |
| Python + pipx + uv | ~100MB | ~100MB |
| Agentic tools (7 before, 2 now) | ~500MB | ~10MB |
| **Total base** | **~1.56GB** | **~0.95-1.05GB** |

The per-agent images add 50-250MB each depending on the tool.

---

## REMAINING OPTIMIZATIONS

1. **Separate Go into its own image or remove from base** — Go is 150MB and
   not needed by most agent tools. Could be a separate image or optional.

2. **Remove Bun from base** — 100MB, only needed by some tools. Could be
   installed per-tool as build_dep.

3. **Use Debian trixie-slim without recommended packages** — We already use
   --no-install-recommends. Good.

4. **Add `rm -rf /var/lib/apt/lists/*` after EVERY apt-get** — We already do
   this in most places. Verify consistency.

5. **Layer ordering** — Put frequently-changing layers last. The tool
   installations should be the last layers so base image layers are cached.

6. **Multi-arch builds** — docker-php-fpm builds for both amd64 and arm64.
   We already have this with the TARGETARCH arg.
