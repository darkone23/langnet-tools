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
# https://github.com/darkone23/whitakers-words
# 
export LANGNET_TOOLS_DIR := shell("pwd")
export LANGNET_TOOLS_HEADER := "🚧 DO NOT EDIT ME DIRECTLY I AM A TEMPLATED FILE 🚧"

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
    cd diogenes && devenv shell perl -- ./server/diogenes-server.pl

langnet:
    just clone langnet-cli
    cd langnet-cli && devenv shell poetry -- install

sidecar:
    just clone langnet-cli
    cd langnet-cli && devenv shell poe -- sidecar

# some examples:
# just compose up -D
# just compose attach
# just compose list
compose *ARGS:
    envsubst < process-compose.tmpl.yaml > process-compose.yaml
    process-compose -p 38080 {{ ARGS }}
