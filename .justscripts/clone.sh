#!/usr/bin/env bash

PROJECT="$1"
DIR=""
REPO=""

if [ "$PROJECT" = "langnet-cli" ]; then
    DIR="langnet-cli"
    REPO="git@github.com:darkone23/langnet-cli"
elif [ "$PROJECT" = "whitakers" ]; then 
    DIR="whitakers-words"
    REPO="git@github.com:darkone23/whitakers-words"
elif [ "$PROJECT" = "diogenes" ]; then 
    DIR="diogenes"
    REPO="git@github.com:darkone23/diogenes"
elif [ "$PROJECT" = "sanskrit-heritage" ]; then 
    DIR="sanskrit-heritage"
    REPO="git@github.com:darkone23/sanskrit-heritage"
elif [ "$PROJECT" = "heritage-platform" ]; then 
    DIR="sanskrit-heritage/Heritage_Platform"
    REPO="git@github.com:darkone23/Heritage_Platform"
elif [ "$PROJECT" = "heritage-resources" ]; then 
    DIR="sanskrit-heritage/Heritage_Resources"
    REPO="git@github.com:darkone23/Heritage_Resources"
elif [ "$PROJECT" = "zen" ]; then 
    DIR="sanskrit-heritage/Zen"
    REPO="git@github.com:darkone23/Zen"
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
