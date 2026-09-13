# goal is to set up language platform
# https://github.com/darkone23/langnet-cli
# 
# https://github.com/darkone23/heritage
#   https://github.com/darkone23/Heritage_Platform
#   https://github.com/darkone23/Heritage_Resources
#   https://github.com/darkone23/Zen
#  
# https://github.com/darkone23/diogenes
#   needs external data from a university source
# 
# https://github.com/darkone23/sanskrit-heritage
#   https://github.com/darkone23/Heritage_Platform
#   https://github.com/darkone23/Heritage_Resources
#   https://github.com/darkone23/Zen
# 
export LANGNET_TOOLS_DIR := shell("pwd")
export LANGNET_TOOLS_HEADER := "🚧 DO NOT EDIT ME DIRECTLY I AM A TEMPLATED FILE 🚧"

export PHI_DIR := LANGNET_TOOLS_DIR / "diogenes/Classics-Data/phi-latin"
export TLG_DIR := LANGNET_TOOLS_DIR / "diogenes/Classics-Data/tlg_e"

default:
    just compose --help

clone project:
    @bash ./.justscripts/clone.sh "{{ project }}"

whitakers:
    just clone whitakers
    cd whitakers-words && devenv shell make

words +ARGS:
    @test -f ~/.local/bin/whitakers-words
    @bash -c "~/.local/bin/whitakers-words {{ ARGS }}"

diogenes:
    just clone diogenes
    cd diogenes && devenv shell make
    cd diogenes && devenv shell make -- -f ./mk.prebuilt-data

sanskrit-heritage:
    just clone sanskrit-heritage
    just clone zen
    just clone heritage-resources
    just clone heritage-platform
    bash .justscripts/setup-heritage-config.sh

langnet-cli:
    just clone langnet-cli
    cd langnet-cli && devenv shell poetry -- install

diogenes-server:
    just clone diogenes
    cd diogenes && devenv shell perl -- ./server/diogenes-server.pl

langnet-cli-server:
    just clone langnet-cli
    cd langnet-cli && devenv shell uvicorn-run
    
langnet-dg-reaper:
    just clone langnet-cli
    cd langnet-cli && devenv shell just -- langnet-dg-reaper

# some examples:
# just compose up -D
# just compose attach
# just compose list
compose *ARGS:
    envsubst < process-compose.tmpl.yaml > process-compose.yaml
    process-compose -p 38080 -f ./process-compose.yaml {{ ARGS }}

# Restart the full service graph: stop the running daemon (best-effort),
# re-render the config, start detached, wait for the webapp health endpoint.
# Used by `just deploy`; also safe standalone.
compose-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    process-compose -p 38080 down >/dev/null 2>&1 || true
    for _ in $(seq 1 30); do
        pgrep -f "process-compose -p 38080" >/dev/null 2>&1 || break
        sleep 0.5
    done
    envsubst < process-compose.tmpl.yaml > process-compose.yaml
    process-compose -p 38080 -f ./process-compose.yaml up -D
    for _ in $(seq 1 45); do
        curl -fsS --max-time 3 http://127.0.0.1:43210/api/health >/dev/null 2>&1 && exit 0
        sleep 2
    done
    echo "webapp /api/health did not come up after restart" >&2
    exit 1

# Deploy prod to a revision (pipeline v1 — HOL-134). Called by the deploy
# workflow (edge runner -> tailscale ssh) on every merge to main; also usable
# by hand on orion: `just deploy <sha>`.
#
# ROLLBACK: re-run the same recipe at the previous revision, e.g.:
#     just deploy 43d5f81
deploy sha:
    #!/usr/bin/env bash
    set -euo pipefail
    git fetch origin "{{ sha }}"
    # Drift guard: a forced checkout would silently revert uncommitted prod
    # changes (real drift was seen 2026-09-12: logrotate + rate-limit env).
    # Refuse unless the worktree exactly matches the target revision.
    if ! git diff --quiet "{{ sha }}"; then
        echo "REFUSING: prod tree differs from {{ sha }} (uncommitted drift):" >&2
        git diff --stat "{{ sha }}" | head -20 >&2
        echo "Land the drift to main via PR first, then re-deploy." >&2
        exit 1
    fi
    git checkout -f -B main "{{ sha }}"
    just compose-restart
    curl -fsS --max-time 10 http://127.0.0.1:43210/api/health >/dev/null
    echo "deploy ok: {{ sha }} (HEAD now $(git rev-parse --short HEAD))"

logrotate-dry-run:
    mkdir -p tmp
    nix shell nixpkgs#logrotate -c logrotate -d -s {{LANGNET_TOOLS_DIR}}/tmp/process-compose-logrotate.status {{LANGNET_TOOLS_DIR}}/process-compose.logrotate

logrotate-run:
    mkdir -p tmp
    nix shell nixpkgs#logrotate -c logrotate -s {{LANGNET_TOOLS_DIR}}/tmp/process-compose-logrotate.status {{LANGNET_TOOLS_DIR}}/process-compose.logrotate

logrotate-loop:
    mkdir -p tmp
    bash -c 'while true; do just -f {{LANGNET_TOOLS_DIR}}/justfile logrotate-run; sleep "${LANGNET_LOGROTATE_INTERVAL_SECONDS:-3600}"; done'

# enter the core developer session
devenv-zell:
    devenv shell bash -- -c "zell"

# socat for port forwarding
forward from to:
    socat TCP-LISTEN:{{to}},fork,bind=0.0.0.0 TCP:127.0.0.1:{{from}}
