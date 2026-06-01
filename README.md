# docker-agentic

Devilbox-style container image for AI coding CLIs.

This repository mirrors `docker-php-fpm` generation conventions but produces a
single `devilboxcommunity/agentic` image without a PHP-version axis. Dockerfiles
are generated from Ansible/Jinja templates and install a base developer runtime
for future `agentic_tools/` entries.

Plan: `.sisyphus/plans/docker-agentic.md` in the parent Devilbox source tree.

## Generate

```bash
make generate
```

This writes:

- `Dockerfiles/base/Dockerfile-latest`
- `Dockerfiles/base/Dockerfile-stable`
- `Dockerfiles/work/Dockerfile-latest`
- `Dockerfiles/work/Dockerfile-stable`

## Build

```bash
make build-base RELEASE=latest
make build-work RELEASE=latest
```

Manual equivalent:

```bash
docker build -f Dockerfiles/work/Dockerfile-latest \
  -t devilboxcommunity/agentic:test .
```

## Test and lint

```bash
make lint
make test
```

## Devilbox integration

The image is intended for a future opt-in Devilbox compose service using the
`devilboxcommunity/agentic:<release>` namespace. Wave 1 only scaffolds this
image repository; Devilbox compose and `dvl agent` integration are later waves.
