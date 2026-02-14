# Repos and Builds

This is a “what lives where” index.

## Primary repos

- `langnet-spec`
  - protobuf schemas (contract)
  - codegen: Python (betterproto2), Zig (zig-protobuf)

- `langnet-cli`
  - Click CLI entrypoint
  - ASGI backend (uvicorn) for stateful logic
  - stores/indexes data in DuckDB
  - calls external engines (Heritage, Diogenes, Whitaker’s)

- `langnet-web`
  - Zig HTTP server + HTML frontend
  - uses protobuf contract types
  - integrates by spawning `langnet-cli` subprocess

- `langnet-tools`
  - harness / process compose
  - helps bring up required external services and binaries

## External / self-hosted deps (selected)

- Sanskrit Heritage ecosystem:
  - `Zen` (OCaml lib)
  - `Heritage_Resources` (data)
  - `Heritage_Platform` (OCaml CGI)
  - `sanskrit-heritage` (httpd harness)

- `diogenes` (Perl server; full functionality requires Packard Humanities CD-ROM data)
- `whitakers-words` (Ada binary)

- Zig libs used by `langnet-web`:
  - `zzz-nossl`
  - `mustache-zig`

```mermaid
flowchart TB

  heritage["Sanskrit Heritage (service)"]
  diogenes["Diogenes (service)"]
  whit["Whitaker's Words (binary)"]

  cli["langnet-cli (runtime consumer)"]
  web["langnet-web (runtime consumer)"]

  cli --> heritage
  cli --> diogenes
  cli --> whit

  web -->|"subprocess -> langnet-cli"| cli
```

## Repo dependency graph

```mermaid
flowchart TB
  spec["langnet-spec"]
  cli["langnet-cli"]
  web["langnet-web"]
  tools["langnet-tools"]
  diogenes["diogenes"]
  heritage["sanskrit-heritage"]
  words["whitakers-words"]

  cli --> spec
  web --> spec
  tools --> diogenes
  tools --> heritage
  tools --> cli
  tools --> web
  tools --> words
```

