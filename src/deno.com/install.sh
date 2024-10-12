#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="deno"
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
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
check_curl_installed() {
    declare -a requiredAptPackagesMissing=()
    if ! [ -r '/etc/ssl/certs/ca-certificates.crt' ]; then
        requiredAptPackagesMissing+=('ca-certificates')
    fi
    if ! command -v curl >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('curl')
    fi
    declare -i requiredAptPackagesMissingCount=${#requiredAptPackagesMissing[@]}
    if [ $requiredAptPackagesMissingCount -gt 0 ]; then
        apt_get_update
        apt_get_checkinstall "${requiredAptPackagesMissing[@]}"
        apt_get_cleanup
    fi
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
install() {
    check_curl_installed
    if [ "$VERSION" == "latest" ]; then
        VERSION="$(curl -s https://dl.deno.land/release-latest.txt)"
    fi
    apt_get_checkinstall unzip
    export DENO_INSTALL="/usr/local"
    curl -fsSL https://deno.land/install.sh | sh -s -- -y $VERSION
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
