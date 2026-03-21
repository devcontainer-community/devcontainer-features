#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly cratesPackage='lumen'
readonly binaryName='lumen'
readonly binaryTargetFolder='/usr/local/bin'
readonly name='lumen'
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
install() {
    utils_check_version "$VERSION"
    apt_get_checkinstall curl ca-certificates build-essential
    export RUSTUP_HOME=/usr/local/rustup
    export CARGO_HOME=/usr/local/cargo
    if ! command -v cargo >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
            sh -s -- -y --no-modify-path --default-toolchain stable
    fi
    export PATH=/usr/local/cargo/bin:$PATH
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        cargo install "$cratesPackage"
    else
        cargo install "$cratesPackage" --version "$VERSION"
    fi
    readonly binaryTargetPath="${binaryTargetFolder}/${binaryName}"
    ln -sf /usr/local/cargo/bin/"$binaryName" "$binaryTargetPath"
    chmod 755 "$binaryTargetPath"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
