Agentic Tools: Overview |
[Agentic Tools: `options.yml`](../doc/contributor/AGENTIC-TOOL-options.yml.md) |
[Agentic Tools: `install.yml`](../doc/contributor/AGENTIC-TOOL-install.yml.md)

---

<h2> Contributor Documentation: Agentic Tools</h2>



## What are Agentic Tools?

Agentic tools are **AI coding agent harness CLIs** (claude-code, codex, copilot,
opencode, pi-coding-agent, reasonix). Each agentic tool gets its own Docker image
layered on top of the work image.

These are NOT spec/workflow tools (like openspec, speckit). Spec/workflow tools
live in the `extra_tools/` directory and are built into the shared base image.

## Directory structure

Each tool lives in its own subdirectory under `agentic_tools/`:

```
agentic_tools/
├── claude-code/
│   ├── install.yml    ← Installation instructions (required)
│   ├── options.yml    ← Tool metadata (required)
│   └── README.md      ← Tool documentation (optional)
├── codex/
│   ├── install.yml
│   ├── options.yml
│   └── README.md
...
└── reasonix/
    ├── install.yml
    ├── options.yml
    └── README.md
```

## Adding a new agentic tool

1. Create a new subdirectory: `mkdir -p agentic_tools/my-agent`
2. Create `options.yml`
3. Create `install.yml`
4. Run `make gen` to regenerate group_vars and Dockerfiles
5. Build the per-agent image: `make build STAGE=my-agent`

Per-agent Dockerfiles are generated to `Dockerfiles/agentic/Dockerfile-{tool}`.
