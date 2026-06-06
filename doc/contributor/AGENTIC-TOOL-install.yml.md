[Agentic Tools: Overview](../../agentic_tools/README.md) |
[Agentic Tools: `options.yml`](AGENTIC-TOOL-options.yml.md) |
Agentic Tools: `install.yml`

---

<h2> Contributor Documentation: Agentic Tools</h2>



# Tool definition: `install.yml`

Agentic tools each get their own Docker image. The Jinja2 template
(`Dockerfile-agentic.j2`) generates a 4-stage multi-stage Dockerfile per tool.


### `check`

* Required: No
* Type: `str`

Shell command to verify installation (e.g. `--version`).


### `all` block

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `type` | Yes | `custom`/`npm`/`pip`/`curl`/`apt` | Install strategy |
| `command` | For custom/curl | `str` | Shell command to install |
| `package` | For npm/pip/apt | `str` | Package name |
| `binary` | No | `str` | Binary name for symlink |
| `version` | No | `str` | Version pin |
| `build_dep` | No | `list[str]` | Apt build dependencies |
| `run_dep` | No | `list[str]` | Apt runtime dependencies |
| `pre` | No | `str` | Shell before install |
| `post` | No | `str` | Shell after install |

The `command` must install the binary to `/opt/agentic-tools/{slug}/bin/`.
