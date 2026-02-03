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
    cd langnet-cli && devenv shell langnet-dg-reaper reap

# some examples:
# just compose up -D
# just compose attach
# just compose list
compose *ARGS:
    envsubst < process-compose.tmpl.yaml > process-compose.yaml
    process-compose -p 38080 -f ./process-compose.yaml {{ ARGS }}

# enter the core developer session
devenv-zell:
    devenv shell bash -- -c "zell"
