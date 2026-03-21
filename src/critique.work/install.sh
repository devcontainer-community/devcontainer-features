#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly binaryName='critique'
readonly binaryTargetFolder='/usr/local/bin'
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
utils_check_version() {
    local version=$1
    if ! [[ "${version:-}" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        printf >&2 '=== [ERROR] Option "version" (value: "%s") is not "latest" or valid semantic version format "X.Y.Z" !\n' \
            "$version"
        exit 1
    fi
}
bun_ensure_installed() {
    if ! command -v bun >/dev/null 2>&1; then
        echo "Bun is not installed. Installing bun to /usr/local..."
        apt_get_checkinstall unzip curl ca-certificates
        export BUN_INSTALL=/usr/local
        curl -fsSL https://bun.sh/install | bash
    fi
}
install() {
    utils_check_version "$VERSION"
    export BUN_INSTALL=/usr/local
    bun_ensure_installed
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        bun install -g critique
    else
        bun install -g "critique@${VERSION}"
    fi
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $binaryName..."
install "$@"
echo "(*) Done!"
