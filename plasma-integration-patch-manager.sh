#!/bin/bash
# plasma-integration-patch-manager.sh
# Installs/uninstalls the forceRefresh patch for plasma-integration

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PATCH_FILE="${SCRIPT_DIR}/plasma-integration-force-refresh.patch"
PLASMA_INT_SRC="${SCRIPT_DIR}/plasma-integration"
BUILD_DIR="${PLASMA_INT_SRC}/build"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 {install|uninstall}"
    echo ""
    echo "Commands:"
    echo "  install   - Apply patch and rebuild plasma-integration"
    echo "  uninstall - Rebuild and install original plasma-integration"
    exit 1
}

check_deps() {
    local missing=()
    for cmd in cmake make patch git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        exit 1
    fi
}

clone_source() {
    echo -e "${GREEN}Cloning plasma-integration source...${NC}"
    rm -rf "$PLASMA_INT_SRC"
    git clone --depth 1 https://invent.kde.org/plasma/plasma-integration.git "$PLASMA_INT_SRC"
}

check_patch() {
    if [[ ! -f "$PATCH_FILE" ]]; then
        echo -e "${RED}Patch file not found: $PATCH_FILE${NC}"
        exit 1
    fi
}

build_and_install() {
    echo -e "${GREEN}Building...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_QT5=OFF -DBUILD_QT6=ON
    make -j$(nproc)

    echo -e "${YELLOW}Installing (requires sudo)...${NC}"
    sudo make install
}

do_install() {
    check_deps
    check_patch
    clone_source

    echo -e "${GREEN}Applying patch...${NC}"
    cd "$PLASMA_INT_SRC"
    patch -p1 < "$PATCH_FILE"

    build_and_install

    echo -e "${GREEN}Done! Restart Qt applications to apply changes.${NC}"
}

do_uninstall() {
    check_deps
    clone_source
    build_and_install

    echo -e "${GREEN}Done! Original plasma-integration restored.${NC}"
}

case "${1:-}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *)         usage ;;
esac
