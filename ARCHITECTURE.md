System name: langnet / project orion
Audience: mostly me - future users if they care

Repos:
- repo: https://github.com/darkone23/langnet-tools
  builds: project harness, whitakers words, heritage platform, diogenes platform
- repo: https://github.com/darkone23/sanskrit-heritage
  builds: httpd harness for the various sanskrit-heritage projects
  used by: langnet-tools

Components (runtime):
- component: langnet-spec
  type: zig+python protocol buffer codegen (semantic structs)
  repo: https://github.com/darkone23/langnet-spec
  talks to: self, generates zig and python code from proto schemas
  deps:
    - betterproto2
    - zig-protobuf
- component: langnet-cli
  type: python data processor
  repo: https://github.com/darkone23/langnet-cli
  talks to: >
     diogenes and sanskrit heritage via http, whitakers words via subproc
     data processing pipeline saves protobuf data into a local duckdb
     derives 'semantic facts' via 'witnesses' (heritage, diogenes, cltk)
  deps:
    - CLTK / spacy
    - requests / beautiful soup
    - lark parsing library
    - uvicorn / starlette / asgi
    - dataclass / orjson / cattrs
    - click for talking to asgi wiring
    - duckdb for indexes / storage
    - langnet-spec for protobuf via betterproto2
    - rich for terminal formatted output
- component: langnet-web
  type: zig http backend + html5 frontend
  repo: https://github.com/darkone23/langnet-web
  talks to: end user via langnet-cli toolkit
  deps:
    - mustache-zig
    - zzz
    - zuckdb (duckdb in zig)
    - langnet-spec (zig-protobuf)
    - tailwind
    - htmx
    - vite/bun/ts

External deps (self-hosted):
- repo: https://github.com/darkone23/Zen
  builds: ocaml zen library for sanskrit heritage platform
  used by: heritage platform / sanskrit-heritage
- repo: https://github.com/darkone23/Heritage_Resources
  builds: data files for the sanskrit heritage platform
  used by: heritage platform / sanskrit-heritage
- repo: https://github.com/darkone23/Heritage_Platform
  builds: ocaml cgi scripts comprising the sanskrit heritage platform
  used by: sanskrit-heritage
- repo: https://github.com/darkone23/diogenes
  builds: perl diogenes server (perseus / LSJ tool)
  used by: langnet-tools
  note: requires packard humanities CD ROM for full functionality (not provided)
- repo: https://github.com/darkone23/whitakers-words
  builds: ada binary for whitakers latin dictionary
  used by: langnet-tools
- repo: https://github.com/darkone23/whitakers-words
  builds: ada binary for whitakers latin dictionary
  used by: langnet-tools
- repo: https://github.com/darkone23/zzz-nossl
  builds: fork of zzz for zig 0.15.x with ssl support removed
  used by: langnet-web
- repo: https://github.com/darkone23/mustache-zig
  builds: fork of mustache-zig for zig 0.15.x
  used by: langnet-web

Key flows:
1) Flow name: backend deps setup
   steps:
    - use langnet-tools on some server to get all required deps running via process compose
    - should result in diogenes, whitakers, and heritage platform
2) Flow name: command line installed
   steps:
    - have backend setup
    - initialize langnet-cli project (submodules, local dirs, data downloads)
      - includes langnet-spec
    - verify you can run basic langnet-cli data processing pipelines
3) Flow name: frontend via http
   steps:
    - have command line installed
    - initialize langnet-web project (submodules, frontend build, zig server)
      - includes langnet-spec
    - run zig http server behind some https proxy like caddy
    - user interacts with web portal to encounter words via langnet-cli
