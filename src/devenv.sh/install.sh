#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly binaryName='devenv'
readonly binaryTargetFolder='/usr/local/bin'
readonly nixBin='/nix/var/nix/profiles/default/bin/nix'
readonly nixDaemonBin='/nix/var/nix/profiles/default/bin/nix-daemon'
readonly nixDaemonSocket='/nix/var/nix/daemon-socket/socket'
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
    local remote_user="${_REMOTE_USER:-root}"
    if [ -z "${remote_user}" ]; then
        echo "ERROR: _REMOTE_USER is not set"
        exit 1
    fi
    apt_get_checkinstall curl ca-certificates
    if [ ! -x "${nixBin}" ]; then
        # sandbox = false is required in Docker/devcontainer environments where
        # the host kernel may not support Nix's sandboxing (seccomp restrictions)
        su "${remote_user}" -c "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --extra-conf 'sandbox = false' --no-confirm --init none"
    fi
    "${nixDaemonBin}" > /dev/null 2>&1 &
    local attempts=0
    until [ -S "${nixDaemonSocket}" ]; do
        sleep 1
        attempts=$((attempts + 1))
        if [ "${attempts}" -ge 30 ]; then
            echo "ERROR: Nix daemon did not become ready within 30 seconds"
            exit 1
        fi
    done
    local nix_flake_ref
    if [ "${VERSION:-latest}" = 'latest' ] || [ -z "${VERSION:-}" ]; then
        nix_flake_ref='github:cachix/devenv'
    else
        nix_flake_ref="github:cachix/devenv/v${VERSION}"
    fi
    local remote_home
    if [ "${remote_user}" = 'root' ]; then
        remote_home='/root'
    else
        remote_home="$(eval echo "~${remote_user}")"
    fi
    su "${remote_user}" -c "
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
        '${nixBin}' profile install \
            --extra-experimental-features 'nix-command flakes' \
            --extra-trusted-public-keys 'devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM=' \
            --extra-substituters 'https://devenv.cachix.org https://cachix.cachix.org' \
            '${nix_flake_ref}#devenv'
    "
    ln -sf "${remote_home}/.nix-profile/bin/${binaryName}" "${binaryTargetFolder}/${binaryName}"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing ${binaryName}..."
install "$@"
echo "(*) Done!"
