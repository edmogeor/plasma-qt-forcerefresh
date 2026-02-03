#!/bin/bash
# plasma-integration-patch-manager.sh
# Installs/uninstalls the forceRefresh patch for plasma-integration

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PATCH_FILE="${SCRIPT_DIR}/plasma-integration-force-refresh.patch"
PLASMA_INT_SRC="${PLASMA_INTEGRATION_SRC:-$HOME/Documents/plasma-integration-master}"
BUILD_DIR="${PLASMA_INT_SRC}/build-patched"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 {install|uninstall}"
    echo ""
    echo "Commands:"
    echo "  install   - Apply patch and rebuild plasma-integration"
    echo "  uninstall - Revert patch and rebuild original"
    echo ""
    echo "Environment variables:"
    echo "  PLASMA_INTEGRATION_SRC - Path to plasma-integration source"
    echo "                           (default: ~/Documents/plasma-integration-master)"
    exit 1
}

check_deps() {
    local missing=()
    for cmd in cmake make patch; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        exit 1
    fi
}

check_source() {
    if [[ ! -f "$PLASMA_INT_SRC/qt6/src/platformtheme/khintssettings.cpp" ]]; then
        echo -e "${RED}plasma-integration source not found at: $PLASMA_INT_SRC${NC}"
        echo "Please set PLASMA_INTEGRATION_SRC or clone the source:"
        echo "  git clone https://invent.kde.org/plasma/plasma-integration.git"
        exit 1
    fi
}

check_patch() {
    if [[ ! -f "$PATCH_FILE" ]]; then
        echo -e "${RED}Patch file not found: $PATCH_FILE${NC}"
        exit 1
    fi
}

is_patched() {
    grep -q "forceStyleRefresh" "$PLASMA_INT_SRC/qt6/src/platformtheme/khintssettings.cpp" 2>/dev/null
}

do_install() {
    check_deps
    check_source
    check_patch

    if is_patched; then
        echo -e "${YELLOW}Patch already applied${NC}"
        return 0
    fi

    echo -e "${GREEN}Applying patch...${NC}"
    cd "$PLASMA_INT_SRC"
    patch -p1 < "$PATCH_FILE"

    echo -e "${GREEN}Building...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_QT5=OFF -DBUILD_QT6=ON
    make -j$(nproc)

    echo -e "${YELLOW}Installing (requires sudo)...${NC}"
    sudo make install

    echo -e "${GREEN}Done! Restart Qt applications to apply changes.${NC}"
}

do_uninstall() {
    check_deps
    check_source
    check_patch

    if ! is_patched; then
        echo -e "${YELLOW}Patch not applied${NC}"
        return 0
    fi

    echo -e "${GREEN}Reverting patch...${NC}"
    cd "$PLASMA_INT_SRC"
    patch -R -p1 < "$PATCH_FILE"

    echo -e "${GREEN}Rebuilding original...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_QT5=OFF -DBUILD_QT6=ON
    make -j$(nproc)

    echo -e "${YELLOW}Installing (requires sudo)...${NC}"
    sudo make install

    echo -e "${GREEN}Done! Original plasma-integration restored.${NC}"
}

case "${1:-}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *)         usage ;;
esac
