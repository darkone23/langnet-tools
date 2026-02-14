# Langnet / Project Orion — Architecture Docs

This folder documents the high-level architecture of Langnet / Project Orion.

## Contents

- `01-contract-and-boundaries.md`
  - The protobuf contract (`langnet-spec`) and component boundaries
- `02-runtime-and-dependencies.md`
  - Runtime topology and external dependencies (Heritage, Diogenes, Whitaker’s)
- `03-repos-and-builds.md`
  - Repo inventory and what each repo builds
- `04-key-flows.md`
  - Key end-to-end flows (setup, query, web request path)

## Integration rule

`langnet-spec` is the interface contract. Components should depend on schema-generated types, not internal implementation details.

