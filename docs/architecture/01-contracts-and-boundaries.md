# Contract and Boundaries

## Contract: `langnet-spec`

`langnet-spec` defines the protobuf schemas used across components.
- Zig types: generated via `zig-protobuf`
- Python types: generated via `betterproto2`

## Boundary: web integrates via CLI subprocess

`langnet-web` integrates by spawning `langnet-cli` as a subprocess.  
The internal ASGI server is a required dependency of the CLI, not a public integration target.

```mermaid
flowchart TB
  spec["langnet-spec (proto contract)"]

  web["langnet-web (zig)"]
  cli["langnet-cli (Click entrypoint)"]
  asgi["langnet-cli internal ASGI backend"]

  web --> spec
  cli --> spec

  web -->|"subprocess: exec langnet-cli"| cli
  cli -->|"requires"| asgi
```

schema generation

```mermaid
flowchart LR
  spec["langnet-spec (proto schemas)"]

  spec -->|"zig-protobuf"| ztypes["Zig generated types"]
  spec -->|"betterproto2"| ptypes["Python generated types"]

  ztypes --> wire[(protobuf bytes)]
  ptypes --> wire

```
