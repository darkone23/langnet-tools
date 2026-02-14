# Runtime and Dependencies

## Runtime topology (current)

- `langnet-web` runs as a Zig HTTP server + browser UI.
- `langnet-web` spawns `langnet-cli` as a subprocess for queries.
- `langnet-cli` depends on an internal ASGI server for stateful logic (caches, contexts).
- The ASGI backend calls external engines and persists/query indexes in DuckDB.

```mermaid
flowchart TB
  user((User))

  web["langnet-web (zig server + UI)"]
  cli["langnet-cli (Click entrypoint)"]
  asgi["langnet-cli internal ASGI backend"]

  duck[(DuckDB indexes)]
  heritage["Sanskrit Heritage (HTTP)"]
  diogenes["Diogenes (HTTP)"]
  whit["Whitaker's Words (binary)"]

  user --> web
  web -->|"subprocess"| cli
  cli -->|"requires"| asgi

  asgi --> duck
  asgi --> heritage
  asgi --> diogenes
  asgi -->|"subprocess"| whit
```
  
## External service requirements (must already exist)

From langnet-cli README expectations:
Sanskrit Heritage Platform: localhost:48080
Diogenes: localhost:8888
Whitaker's Words binary: ~/.local/bin/whitakers-words
Automatic downloads on first use:
CLTK models to ~/cltk_data/
CDSL data to ~/cdsl_data/
Dependency internals (implementation detail)External service requirements (must already exist)
From langnet-cli README expectations:
Sanskrit Heritage Platform: localhost:48080
Diogenes: localhost:8888
Whitaker's Words binary: ~/.local/bin/whitakers-words
Automatic downloads on first use:
CLTK models to ~/cltk_data/
CDSL data to ~/cdsl_data/

## Dependency internals (implementation detail)

```mermaid
flowchart TB
  asgi["ASGI backend"]
  logic["handlers (caches, contexts)"]

  duck[(DuckDB)]
  cltk["CLTK models (~/cltk_data)"]
  cdsl["CDSL data (~/cdsl_data)"]

  heritage["Heritage :48080"]
  diogenes["Diogenes :8888"]
  whit["Whitaker's Words"]

  asgi --> logic
  logic --> duck
  logic --> cltk
  logic --> cdsl
  logic --> heritage
  logic --> diogenes
  logic -->|"subprocess"| whit
```
