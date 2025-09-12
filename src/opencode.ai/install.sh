#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="opencode.ai"
cd $HOME
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
    apt_get_checkinstall curl ca-certificates unzip
    su $_REMOTE_USER -c "curl -fsSL https://opencode.ai/install | bash"
    apt_get_cleanup
}
ln -sf $HOME/.opencode/bin/opencode /usr/local/bin/opencode
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
