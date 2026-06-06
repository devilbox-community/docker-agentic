# docker-php-fpm Multi-Stage Architecture — Research Log

## Date: 2026-06-05
## Source: https://github.com/devilbox-community/docker-php-fpm

---

## 1. OVERALL STAGE CHAIN

docker-php-fpm uses a 5-stage image chain:

```
base → mods → prod → slim → work
```

Each stage FROMs the previous stage's published image (not a local build stage).
This means each stage is independently buildable once its parent is published to Docker Hub.

### Stage purposes:

| Stage | Purpose | Size impact |
|-------|---------|-------------|
| base  | Minimal PHP-FPM runtime from Debian slim | ~150MB |
| mods  | PHP extensions built from source (builder pattern) | +compiler toolchain in builder, only .so files in final |
| prod  | mods + production config tweaks | negligible |
| slim  | prod + cleanup (remove dev headers, man pages, etc.) | -50-100MB |
| work  | slim + CLI tools (composer, wp-cli, etc.) via builder pattern | +toolchain in builder, only binaries in final |

---

## 2. MULTI-STAGE BUILDER PATTERN (THE KEY INSIGHT)

The work stage (`Dockerfile-work.j2`) is actually **7 sub-stages**:

```
Stage 1: WORK-HELP-BUILDER   — FROM slim, installs build toolchain (composer, nvm, pip, rubygem)
Stage 2: WORK-HELP           — FROM slim, COPY only built binaries from Stage 1
Stage 3: WORK-HELP-TEST      — FROM work-help, runs `check` commands to verify binaries
Stage 4: WORK-TOOLS-BUILDER  — FROM work-help, installs php_tools with build_dep
Stage 5: WORK-TOOLS          — FROM work-help, COPY only tool binaries from Stage 4
Stage 6: WORK-TOOLS-TEST     — FROM work-tools, runs `check` commands
Stage 7: WORK (FINAL)        — FROM work-tools, adds labels
```

### Why this matters for image size:

1. **BUILDER stages install compilers and -dev packages** (gcc, libssl-dev, etc.)
   These stay in the builder image and are NEVER copied to the final image.

2. **Final stages COPY only the built artifacts** — binaries, .so files, npm global
   packages, pip packages, Ruby gems. No compilers, no headers, no -dev libs.

3. **TEST stages are separate** — they run `check` commands and fail the build early
   if a tool doesn't work, without bloating the final image.

4. **Each tool gets its own RUN layer comment** — `# -------------------- toolname --------------------`
   This makes the Dockerfile self-documenting and debuggable.

---

## 3. BUILD_DEP vs RUN_DEP SEPARATION

Each tool definition has two dependency lists:

```yaml
build_dep: [libssl-dev, pkg-config]   # Only needed during build
run_dep:  [libssl3]                    # Needed at runtime
```

- `build_dep` packages are installed ONLY in the BUILDER stage
- `run_dep` packages are installed in BOTH the BUILDER and the FINAL stage

This is the PRIMARY mechanism for image size reduction. Without it, every
-dev package bloats the final image.

---

## 4. HOW THIS APPLIES TO docker-agentic

### Current state (what we implemented):

```
base → work → per-agent
```

Our `Dockerfile-agentic.j2` has 4 stages:
```
Stage 1: BUILDER   — FROM work, installs agent tool
Stage 2: FINAL     — FROM work, COPY binary from builder
Stage 3: TEST      — FROM final, runs check
Stage 4: FINAL     — FROM final, adds labels
```

### What we're MISSING (gaps to close):

1. **No build_dep/run_dep separation in practice** — Most of our agent tools have
   `build_dep: []` and `run_dep: []`. But the base image already has build-essential
   and libssl-dev installed (from Dockerfile-base.j2). These should NOT be in
   the base image — they should be in the BUILDER stage only.

2. **Base image has build toolchain** — The base Dockerfile installs:
   - build-essential (gcc, g++, make)
   - libffi-dev, libssl-dev, python3-dev
   - cmake, pkg-config
   These are ~200-300MB of compiler toolchain that should NOT be in the base image.
   
   In docker-php-fpm, the base image is MINIMAL — just the runtime. Build tools
   go in the builder stages.

3. **No post-build cleanup** — After installing agent tools, we don't remove:
   - npm cache
   - pip cache
   - apt lists
   - temporary files
   
   docker-php-fpm's builder stages install, then the final stage only COPYs.

4. **No `already_avail` pattern** — docker-php-fpm's install.yml supports an
   `already_avail` key for PHP versions where the extension is already present.
   We don't have this for agentic tools (less critical since we have no version axis).

5. **No `exclude` usage** — docker-php-fpm excludes certain PHP versions from
   building specific modules. Our `exclude: []` is always empty.

---

## 5. CONCRETE SIZE REDUCTION PLAN

### Step 1: Move build toolchain out of base image

Currently in `Dockerfile-base.j2`:
```
apt-get install build-essential cmake gcc g++ libffi-dev libssl-dev python3-dev pkg-config
```

These should be REMOVED from the base image. Instead:
- Add them as `build_dep` on tools that need them
- The macros already support `build_dep` — they install in the builder stage only

### Step 2: Add npm/pip cache cleanup to macros

In `macros-work.j2`, after each `npm install -g`:
```
&& npm cache clean --force
```

After each `pipx install`:
```
&& pip cache purge
```

### Step 3: Add apt cleanup to builder stages

After `apt-get install` in builder stages:
```
&& apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Step 4: Split the base image into runtime-only

The base image should contain ONLY runtime dependencies:
- ca-certificates, curl, git, gh, jq, ripgrep, tmux, vim, etc. (user-facing tools)
- Node.js (runtime, not build tools)
- Go (runtime, not build tools)
- Python (runtime, not python3-dev)

Build dependencies (gcc, g++, make, cmake, *-dev packages) should go into
a separate builder stage or be specified per-tool as build_dep.

### Step 5: Consider a `slim` equivalent

docker-php-fpm has a `slim` stage that strips out:
- man pages
- documentation
- locale data (except en_US)
- apt cache

We could add a similar cleanup RUN at the end of our base Dockerfile.

---

## 6. docker-php-fpm CONVENTIONS WE ALREADY MATCH

✓ `###` / `################################################################` comment blocks
✓ `set -eux` on every RUN
✓ `# vi: ft=dockerfile` header
✓ `# Auto-generated via Ansible: edit ...` comment
✓ OCI labels with org.opencontainers.image.*
✓ `--no-install-recommends --no-install-suggests` on apt-get
✓ Multi-stage FROM chain
✓ BUILDER → COPY → FINAL pattern
✓ `check-stage-is-set` / `check-parent-image-exists` guards
✓ `lint-ansible` = gen + git diff --quiet
✓ `.gitkeep` in Dockerfiles subdirectories
✓ `make build STAGE=...` unified interface
✓ Separate generators for modules vs tools
✓ Jinja2 macros with get_type/get_binary/get_build_dep pattern

---

## 7. docker-php-fpm CONVENTIONS STILL MISSING

✗ Build toolchain in base image (should be builder-only)
✗ No post-install cleanup in macros (npm cache, pip cache)
✗ No `slim` cleanup stage
✗ Agent tools don't use build_dep/run_dep (all empty arrays)
✗ No apt-get clean after builder stage installs
✗ No `already_avail` support in install.yml
