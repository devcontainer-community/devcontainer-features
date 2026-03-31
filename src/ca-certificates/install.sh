#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="ca-certificates"
readonly caCertificatesDir="/usr/local/share/ca-certificates"
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
download_file() {
    local url=$1
    local target=$2
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$target" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$target" "$url"
    else
        apt_get_checkinstall curl
        curl -fsSL -o "$target" "$url"
    fi
}
install() {
    apt_get_checkinstall ca-certificates
    if [ -n "${URLS:-}" ]; then
        mkdir -p "$caCertificatesDir"
        while IFS= read -r url; do
            url="$(echo "$url" | tr -d '[:space:]')"
            if [ -n "$url" ]; then
                echo "Downloading certificate from $url..."
                local filename
                filename="$(basename "$url" | tr -cd 'a-zA-Z0-9._-')"
                if [ -z "$filename" ]; then
                    echo "Skipping '$url': could not derive a safe filename."
                    continue
                fi
                download_file "$url" "$caCertificatesDir/$filename"
            fi
        done <<< "$URLS"
        update-ca-certificates
    fi
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
