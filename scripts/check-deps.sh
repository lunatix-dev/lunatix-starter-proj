#!/bin/bash

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-utils.sh"

# --- Initialization & Detection ---

MISSING_SYSTEM_PKGS=()
MISSING_FRONTEND_DEPS=()
PKG_MGR="unknown"
INSTALL_CMD=""

# Package mappings for various distributions
declare -A ARCH_PKGS=(
    ["bun"]="bun-bin" ["node"]="nodejs" ["jq"]="jq" ["meson"]="meson"
    ["ninja"]="ninja" ["g++"]="gcc" ["pkg-config"]="pkgconf"
    ["rustc"]="rust" ["cargo"]="rust" ["asio"]="asio" ["libsoup-2.4"]="libsoup"
    ["webkit2gtk-4.0"]="webkit2gtk" ["gtk+-3.0"]="gtk3" ["ayatana-appindicator3-0.1"]="libayatana-appindicator"
)

declare -A APT_PKGS=(
    ["bun"]="bun" ["node"]="nodejs" ["jq"]="jq" ["meson"]="meson"
    ["ninja"]="ninja-build" ["g++"]="build-essential" ["pkg-config"]="pkg-config"
    ["rustc"]="rustc" ["cargo"]="cargo" ["asio"]="libasio-dev" ["libsoup-2.4"]="libsoup-2.4-dev"
    ["webkit2gtk-4.0"]="libwebkit2gtk-4.0-dev" ["gtk+-3.0"]="libgtk-3-dev" ["ayatana-appindicator3-0.1"]="libayatana-appindicator3-dev"
)

declare -A DNF_PKGS=(
    ["bun"]="bun" ["node"]="nodejs" ["jq"]="jq" ["meson"]="meson"
    ["ninja"]="ninja-build" ["g++"]="gcc-c++" ["pkg-config"]="pkgconf-pkg-config"
    ["rustc"]="rustc" ["cargo"]="cargo" ["asio"]="asio-devel" ["libsoup-2.4"]="libsoup-devel"
    ["webkit2gtk-4.0"]="webkit2gtk3-devel" ["gtk+-3.0"]="gtk3-devel" ["ayatana-appindicator3-0.1"]="libayatana-appindicator3-devel"
)

detect_pkg_mgr() {
    if command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    elif command -v apt-get &> /dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="sudo apt-get install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y"
    fi
}

# --- Helper Functions ---

check_cmd() {
    local cmd=$1
    local name=$2
    if ! command -v "$cmd" &> /dev/null; then
        log_error "MISSING: $name ($cmd)"
        MISSING_SYSTEM_PKGS+=("$cmd")
        return 1
    fi
    log_info "OK: $name is installed."
    return 0
}

check_lib() {
    local lib=$1
    local name=$2
    if ! pkg-config --exists "$lib" &> /dev/null; then
        log_error "MISSING: Library $name ($lib)"
        MISSING_SYSTEM_PKGS+=("$lib")
        return 1
    fi
    log_info "OK: Library $name is found."
    return 0
}

# --- Core Task Logic ---

check_system_deps() {
    local failed=0
    local compiler=${1:-g++}

    echo "Checking system tools and libraries..."
    check_cmd "bun" "Bun" || failed=1
    check_cmd "node" "Node.js" || failed=1
    check_cmd "jq" "jq" || failed=1
    check_cmd "meson" "Meson" || failed=1
    check_cmd "ninja" "Ninja" || failed=1
    check_cmd "$compiler" "C++ Compiler ($compiler)" || failed=1
    check_cmd "pkg-config" "pkg-config" || failed=1
    check_cmd "rustc" "Rust Compiler" || failed=1
    check_cmd "cargo" "Cargo" || failed=1
    
    if command -v cargo-tauri &> /dev/null; then
        echo -e "${GREEN}OK: Tauri CLI (Cargo) found.${NC}"
    elif [ -f "apps/desktop-app/node_modules/.bin/tauri" ]; then
        echo -e "${GREEN}OK: Tauri CLI (Bun-local) found.${NC}"
    elif (cd apps/desktop-app && bun run tauri --version &> /dev/null); then
        echo -e "${GREEN}OK: Tauri CLI (Bun-run) found.${NC}"
    else
        echo -e "${RED}MISSING: Tauri CLI (neither Global Cargo nor Local Bun found)${NC}"
        MISSING_SYSTEM_PKGS+=("cargo-tauri")
        failed=1
    fi

    check_lib "asio" "Asio" || failed=1
    check_lib "libsoup-2.4" "libsoup 2.4" || failed=1
    check_lib "webkit2gtk-4.0" "WebKit2GTK 4.0" || failed=1
    check_lib "gtk+-3.0" "GTK 3" || failed=1
    
    # Optional indicator check
    # if ! pkg-config --exists "ayatana-appindicator3-0.1" &> /dev/null; then
    #     echo -e "${YELLOW}OPTIONAL: Library Ayatana AppIndicator 3 is missing (tray might not work)${NC}"
    #     MISSING_SYSTEM_PKGS+=("ayatana-appindicator3-0.1")
    #     # Don't fail the build just for this, tauri might fall back or it might be really optional
    # else
    #     echo -e "${GREEN}OK: Library Ayatana AppIndicator 3 is found.${NC}"
    # fi

    return $failed
}

install_system_pkgs() {
    if [ ${#MISSING_SYSTEM_PKGS[@]} -eq 0 ] || [ "$PKG_MGR" == "unknown" ]; then
        return 0
    fi

    local to_install=()
    for pkg in "${MISSING_SYSTEM_PKGS[@]}"; do
        case $PKG_MGR in
            pacman) to_install+=("${ARCH_PKGS[$pkg]}") ;;
            apt)    to_install+=("${APT_PKGS[$pkg]}") ;;
            dnf)    to_install+=("${DNF_PKGS[$pkg]}") ;;
        esac
    done

    # Unique and filter empty
    to_install=($(echo "${to_install[@]}" | tr ' ' '\n' | sort -u | grep -v '^$'))

    if [ ${#to_install[@]} -gt 0 ]; then
        log_warn "Missing system packages: ${to_install[*]}"
        read -p "Install them now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $INSTALL_CMD "${to_install[@]}" || return 1
            return 2 # Signal success/re-run
        fi
    fi
    return 1
}

install_frontend_deps() {
    if [ ${#MISSING_FRONTEND_DEPS[@]} -eq 0 ]; then return 0; fi

    log_warn "Missing frontend dependencies. Run 'bun install'?"
    read -p "[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bun install || return 1
        return 2 # Signal success/re-run
    fi
    return 1
}

# --- Main ---

main() {
    detect_pkg_mgr
    
    local sys_status=0
    local web_status=0

    check_system_deps "$1" || sys_status=1

    if [ $sys_status -eq 0 ]; then
        log_info "All dependencies met."
        exit 0
    fi

    echo ""
    local rerun=0

    # Try installing system packages
    install_system_pkgs
    status=$?
    [ $status -eq 2 ] && rerun=1
    [ $status -eq 1 ] && [ $rerun -eq 0 ] && exit 1

    if [ $rerun -eq 1 ]; then
        log_info "Dependencies updated. Re-running check..."
        exec "$0" "$@"
    fi

    log_error "Please resolve missing dependencies and try again."
    exit 1
}

main "$@"
