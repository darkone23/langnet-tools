#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(readlink -f "$SCRIPT_DIR/../sanskrit-heritage")"
PLATFORM_DIR="$(readlink -f "$ROOT_DIR/Heritage_Platform")"
ZEN_DIR="$(readlink -f "$ROOT_DIR/Zen")"
RESOURCES_DIR="$(readlink -f "$ROOT_DIR/Heritage_Resources")"

echo "=== Sanskrit Heritage Platform Config ==="
echo ""

check_dir() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory not found: $1"
        echo "Please clone all dependencies first:"
        echo "  - Zen"
        echo "  - Heritage_Resources"
        echo "  - Heritage_Platform"
        exit 1
    fi
}

check_dir "$ZEN_DIR"
check_dir "$RESOURCES_DIR"
check_dir "$PLATFORM_DIR"

cd "$PLATFORM_DIR"

cat > SETUP/dev_config.txt << EOF
ZENDIR='$ZEN_DIR/ML'
PLATFORM='Station'
TRANSLIT='VH'
LEXICON='MW'
DISPLAY='roma'
SERVERHOST='127.0.0.1'
SERVERPUBLICDIR='$ROOT_DIR/webroot/htdocs/'
SKTDIRURL='/skt/'
SKTRESOURCES='$RESOURCES_DIR/'
CGIBINURL='/cgi-bin/skt/'
CGIDIR='$ROOT_DIR/webroot/cgi-bin/'
CGIEXT=''
MOUSEACTION='CLICK'
CAPTION='Dev setup'
EOF

ln -sf dev_config.txt SETUP/config

echo "Generated: SETUP/dev_config.txt"
echo "Symlinked: SETUP/config -> SETUP/dev_config.txt"
echo ""
echo "To build and install:"
echo "  cd $ROOT_DIR"
echo "  devenv shell bash -- -c 'cd Zen/ML; make depend && make all'"
echo "  devenv shell bash -- -c 'cd Heritage_Platform; ./configure && make && make install'"
