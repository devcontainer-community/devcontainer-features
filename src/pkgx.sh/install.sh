#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="pkgx"
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
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
    export DENO_INSTALL="/usr/local"
    curl -fsSL https://pkgx.sh | sh
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
