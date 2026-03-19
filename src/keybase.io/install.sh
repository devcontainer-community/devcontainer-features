#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="keybase"

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
    apt_get_checkinstall curl ca-certificates
    architecture=$(dpkg --print-architecture)
    case "${architecture}" in
        amd64) arch_suffix="amd64" ;;
        arm64) arch_suffix="arm64" ;;
        *)
            echo "Keybase does not support machine architecture '${architecture}'. Please use an x86-64 or ARM64 machine."
            exit 1
            ;;
    esac
    local deb_file="keybase_${arch_suffix}.deb"
    curl -fsSL "https://prerelease.keybase.io/${deb_file}" -o "/tmp/${deb_file}"
    # Extract binaries directly to avoid unresolvable GUI dependencies (e.g. fuse,
    # libasound2, libgtk-3-0) that are renamed or unavailable in Ubuntu 24.04+.
    local extract_dir
    extract_dir="$(mktemp -d)"
    dpkg-deb -x "/tmp/${deb_file}" "${extract_dir}"
    if [ ! -f "${extract_dir}/usr/bin/keybase" ]; then
        echo "ERROR: keybase binary not found in extracted package at ${extract_dir}/usr/bin/keybase"
        rm -rf "${extract_dir}" "/tmp/${deb_file}"
        exit 1
    fi
    install -m 0755 "${extract_dir}/usr/bin/keybase" /usr/local/bin/keybase
    rm -rf "${extract_dir}" "/tmp/${deb_file}"
    apt_get_cleanup
}

echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
