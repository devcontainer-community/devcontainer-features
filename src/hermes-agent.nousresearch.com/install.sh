#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="hermes"
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
install() {
    apt_get_checkinstall curl ca-certificates git xz-utils
    su "${_REMOTE_USER}" -c "curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash -s -- --skip-setup"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
