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

# Build + install the prod whitakers-words binary (HOL-148). The binary's
# data dir is compiled in as "." (CWD-relative), so the wrapper cd's into the
# clone before exec. That wrapper is the contract: langnet-cli's
# WhitakersClient and the `words` recipe both resolve
# ~/.local/bin/whitakers-words. Idempotent: clone no-ops when present, make
# is incremental, install overwrites, smoke gates on a real lookup.
whitakers-install:
    #!/usr/bin/env bash
    set -euo pipefail
    just whitakers
    mkdir -p ~/.local/bin
    printf '#!/usr/bin/env sh\ncd %s\nexec ./bin/words "$@"\n' \
      "$LANGNET_TOOLS_DIR/whitakers-words" > ~/.local/bin/whitakers-words
    chmod +x ~/.local/bin/whitakers-words
    out="$(echo lupus | ~/.local/bin/whitakers-words 2>/dev/null || true)"
    if ! echo "$out" | grep -q "wolf"; then
        echo "whitakers smoke lookup FAILED (~/.local/bin/whitakers-words did not resolve 'lupus'):" >&2
        echo "$out" >&2
        exit 1
    fi
    echo "whitakers-install ok: 'lupus' -> 'wolf; grappling iron' (built revision: $(git -C "$LANGNET_TOOLS_DIR/whitakers-words" rev-parse --short HEAD))"

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

# Restart the full service graph: re-render the config, restart through
# whatever supervisor owns the daemon, wait for the webapp health endpoint.
# Used by `just deploy`; also safe standalone.
#
# Supervisor routing (HOL-147): when orion-services has installed the
# boot-persistence unit (systemctl --user cat langnet-compose.service),
# restarts go through systemd so supervision is continuous — a bare `up -D`
# here would start a detached daemon the unit doesn't own and fight it on
# the next boot/restart (the unit's ExecStart would hit the busy port).
# On a pre-unit box the v1 detached path below runs unchanged.
compose-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    # ssh/ansible sessions don't always carry the user bus env (the fleet
    # justfile's pc_prelude exports this for the same reason)
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if systemctl --user cat langnet-compose.service >/dev/null 2>&1; then
        envsubst < process-compose.tmpl.yaml > process-compose.yaml
        if systemctl --user is-active --quiet langnet-compose.service; then
            systemctl --user restart langnet-compose.service
        else
            # unit installed but inactive (booted but never started, or a
            # hand `stop`): clear any legacy detached daemon holding the
            # port, then start under systemd
            process-compose -p 38080 down >/dev/null 2>&1 || true
            systemctl --user start langnet-compose.service
        fi
        for _ in $(seq 1 45); do
            curl -fsS --max-time 3 http://127.0.0.1:43210/api/health >/dev/null 2>&1 && exit 0
            sleep 2
        done
        echo "webapp /api/health did not come up after systemd restart" >&2
        exit 1
    fi
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
# Component sync (v1 semantics): the service-bearing clones (langnet-cli,
# diogenes, sanskrit-heritage) are fast-forwarded to the head of the branch
# each already tracks — this is what carries component PRs (langnet-cli,
# whitakers-words, diogenes, ...) to prod. Declared revisions come later with
# the orion-services IaC role. whitakers-words is deliberately NOT synced: no
# running service reads its clone (prod runs the built binary at
# ~/.local/bin/whitakers-words); its deploys stay manual (`just whitakers`
# build+install on orion).
#
# ROLLBACK: re-run the same recipe at the previous revision, e.g.:
#     just deploy 43d5f81
deploy sha:
    #!/usr/bin/env bash
    set -euo pipefail
    # Self-heal the fetch path (HOL-202): origin must be the public https
    # URL — the repo is public, so fetches need no key material on the box.
    # An ssh:// origin makes every deploy depend on a deploy key surviving
    # on orion (it drifted once and git fetch died with "Permission denied
    # (publickey)"). Idempotent: a no-op when origin already matches.
    git remote set-url origin https://github.com/darkone23/langnet-tools
    git fetch origin "{{ sha }}"
    # Drift guard (uncommitted-drift-only, board-corrected semantics):
    # refuse when the worktree or index carries uncommitted changes vs HEAD —
    # a forced checkout would silently revert those (real drift was seen
    # 2026-09-12: logrotate + rate-limit env). Version skew between HEAD and
    # the target revision is exactly what a deploy reconciles, so being
    # behind/ahead of the target is NOT drift. Comparing against the target
    # here would refuse every real deploy (and rollback) — the first three
    # runs only passed because the tree had been hand-placed at the target.
    if ! git diff --quiet HEAD -- . || ! git diff --cached --quiet; then
        echo "REFUSING: uncommitted prod drift (worktree/index vs HEAD):" >&2
        git status --short >&2
        echo "Land the drift to main via PR first, then re-deploy." >&2
        exit 1
    fi
    git checkout -f -B main "{{ sha }}"
    # --- component sync: ff to the head of each tracked branch ---
    # The merge itself is the arbiter (no pre-guard: a no-op ff must succeed
    # even when a clone carries prod-local files, e.g. sanskrit-heritage's
    # httpd.conf — git only aborts when the update would CLOBBER local
    # changes). devenv.lock is volatile on prod (devenv regenerates it on
    # eval), so when a moving ff conflicts on the lock, discard ours — the
    # repo pin wins — and retry once, loudly. Any other clobber-conflict is
    # real drift: refuse with the clone's status.
    for comp in langnet-cli diogenes sanskrit-heritage; do
        if [ ! -d "{{LANGNET_TOOLS_DIR}}/$comp/.git" ]; then
            echo "REFUSING: $comp clone missing — run 'just clone $comp' on orion first" >&2
            exit 1
        fi
        d="{{LANGNET_TOOLS_DIR}}/$comp"
        branch=$(git -C "$d" rev-parse --abbrev-ref HEAD)
        git -C "$d" fetch origin "$branch"
        if ! git -C "$d" merge --ff-only "origin/$branch" 2>/tmp/ff-err.$comp; then
            if ! git -C "$d" diff --quiet -- ':(exclude)devenv.lock'; then
                echo "REFUSING: $comp has real prod drift (beyond the volatile devenv.lock):" >&2
                cat /tmp/ff-err.$comp >&2
                git -C "$d" status --short >&2
                echo "Capture the drift to $branch via PR, then re-deploy." >&2
                exit 1
            fi
            echo "component $comp: discarding volatile devenv.lock (devenv regenerates it; repo pin wins)" >&2
            git -C "$d" checkout -- devenv.lock
            git -C "$d" merge --ff-only "origin/$branch" \
                || { echo "REFUSING: $comp cannot fast-forward to origin/$branch even after discarding the volatile lock (diverged?)" >&2; exit 1; }
        fi
        echo "component $comp -> $(git -C "$d" rev-parse --short HEAD) ($branch)"
    done
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
