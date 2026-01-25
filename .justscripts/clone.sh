#!/usr/bin/env bash

PROJECT="$1"
DIR=""
REPO=""

if [ "$PROJECT" = "langnet-cli" ]; then
    DIR="langnet-cli"
    REPO="https://github.com/darkone23/langnet-cli"
elif [ "$PROJECT" = "whitakers" ]; then 
    DIR="whitakers-words"
    REPO="https://github.com/darkone23/whitakers-words"
elif [ "$PROJECT" = "diogenes" ]; then 
    DIR="diogenes"
    REPO="https://github.com/darkone23/diogenes"
else
    echo "Unexpected project: $PROJECT"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    git clone "$REPO" "$DIR"
else
    echo "$DIR already setup"
    exit 0
fi
