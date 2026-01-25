# goal is to set up language platform
# https://github.com/darkone23/langnet
# 
# https://github.com/darkone23/heritage
#   https://github.com/darkone23/Heritage_Platform
#   https://github.com/darkone23/Heritage_Resources
#   https://github.com/darkone23/Zen
#  
# https://github.com/darkone23/diogenes
#   needs external data from a university source
# 
# https://github.com/darkone23/whitakers-words
# 

default:
    just compose --help

clone project:
    #!/usr/bin/env bash

    DIR=""
    REPO=""

    if [ "{{ project }}" = "langnet" ]; then
        DIR="langnet"
        REPO="https://github.com/darkone23/langnet"
    elif [ "{{ project }}" = "whitakers" ]; then 
        DIR="whitakers-words"
        REPO="https://github.com/darkone23/whitakers-words"
    elif [ "{{ project }}" = "diogenes" ]; then 
        DIR="diogenes"
        REPO="https://github.com/darkone23/diogenes"
    else
        echo "Unexpected project: {{ project }}"
        exit 1
    fi

    if [ ! -d "$DIR" ]; then
        git clone "$REPO" "$DIR"
    else
        echo "$DIR already setup"
        exit 0
    fi

diogenes:
    #!/usr/bin/env bash
    
    # TODO: start this with process compose?
    just clone diogenes
    cd diogenes && exec devenv shell perl -- ./server/diogenes-server.pl

langnet:
    #!/usr/bin/env bash
    
    # TODO: start this with process compose?
    just clone langnet
    cd langnet
    devenv shell jsbuild
    exec devenv shell poe -- dev

sidecar:
    #!/usr/bin/env bash
    
    # TODO: start this with process compose?
    # just clone langnet
    cd langnet
    # devenv shell jsbuild
    exec devenv shell poe -- sidecar

# some examples:
# just compose up -D
# just compose attach
# just compose list
compose *ARGS:
    process-compose -p 38080 {{ ARGS }}
