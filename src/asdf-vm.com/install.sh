#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="asdf"
readonly githubRepository="asdf-vm/asdf"
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
apt_get_checkinstall() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests --option 'Debug::pkgProblemResolver=true' --option 'Debug::pkgAcquire::Worker=1' "$@"
    fi
}
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
github_get_latest_release() {
    if [ -z "$1" ]; then
        echo "Usage: get_latest_github_release <owner/repo>"
        return 1
    fi
    local repo="$1"
    curl -s -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$repo/releases/latest" | \
        sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | sed 's/^v//'
}
utils_check_version() {
    local version=$1
    if ! [[ "${version:-}" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        printf >&2 '=== [ERROR] Option "version" (value: "%s") is not "latest" or valid semantic version format "X.Y.Z" !\n' \
            "$version"
        exit 1
    fi
}
detect_os() {
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$os" in
        linux) echo "linux" ;;
        darwin) echo "darwin" ;;
        *) echo >&2 "Unsupported OS: $os"; exit 1 ;;
    esac
}
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64 | amd64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        i386 | i686) echo "386" ;;
        *) echo >&2 "Unsupported architecture: $arch"; exit 1 ;;
    esac
}
version_lte() {
    # Returns 0 (true) if $1 <= $2
    [ "$1" = "$(printf '%s\n%s' "$1" "$2" | sort -V | head -n1)" ]
}
install_legacy() {
    # Legacy installation via git clone for versions <= 0.16.0
    apt_get_checkinstall git curl ca-certificates
    su $_REMOTE_USER -c "git clone https://github.com/$githubRepository.git $_REMOTE_USER_HOME/.asdf --branch v$VERSION"
    apt_get_cleanup
    echo '. "$HOME/.asdf/asdf.sh"' >>"$_REMOTE_USER_HOME/.bashrc"
    echo '. "$HOME/.asdf/completions/asdf.bash"' >>"$_REMOTE_USER_HOME/.bashrc"
}
install_binary() {
    # Binary installation for versions > 0.15.0
    apt_get_checkinstall curl ca-certificates
    local os arch asset_name download_url install_dir
    os="$(detect_os)"
    arch="$(detect_arch)"
    asset_name="asdf-v${VERSION}-${os}-${arch}.tar.gz"
    download_url="https://github.com/${githubRepository}/releases/download/v${VERSION}/${asset_name}"
    install_dir="$_REMOTE_USER_HOME/.asdf"
    echo "Downloading $asset_name..."
    mkdir -p "$install_dir/bin"
    curl -fsSL "$download_url" | tar -xz -C "$install_dir/bin"
    chown -R "$_REMOTE_USER:$_REMOTE_USER" "$install_dir"
    apt_get_cleanup
    # Add asdf to PATH in shell config
    echo 'export PATH="$HOME/.asdf/bin:$PATH"' >>"$_REMOTE_USER_HOME/.bashrc"
}
install() {
    utils_check_version "$VERSION"
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(github_get_latest_release "$githubRepository")
    fi
    if version_lte "$VERSION" "0.16.0"; then
        echo "Installing legacy bash version (v$VERSION)..."
        install_legacy
    else
        echo "Installing binary version (v$VERSION)..."
        install_binary
    fi
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
