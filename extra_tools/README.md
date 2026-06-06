Extra Tools: Overview |
[Extra Tools: `options.yml`](../doc/contributor/EXTRA-TOOL-options.yml.md) |
[Extra Tools: `install.yml`](../doc/contributor/EXTRA-TOOL-install.yml.md)

---

<h2> Contributor Documentation: Extra Tools</h2>



## What are Extra Tools?

Extra tools are **specification and workflow utilities** that are shared across
all agent harness images. They are built into the **base image** and available
to every per-agent image.

These are NOT agent harness tools (like claude-code, codex, copilot, etc.).
Agent harness tools live in the `agentic_tools/` directory and each gets its own
Docker image.

## Directory structure

Each tool lives in its own subdirectory under `extra_tools/`:

```
extra_tools/
├── openspec/
│   ├── install.yml    ← Installation instructions (required)
│   ├── options.yml    ← Tool metadata (required)
│   └── README.md      ← Tool documentation (optional)
└── speckit/
    ├── install.yml
    ├── options.yml
    └── README.md
```

## Adding a new extra tool

1. Create a new subdirectory: `mkdir -p extra_tools/my-tool`
2. Create `options.yml`
3. Create `install.yml`
4. Run `make gen` to regenerate group_vars and Dockerfiles
5. Rebuild the base image: `make build STAGE=base`
