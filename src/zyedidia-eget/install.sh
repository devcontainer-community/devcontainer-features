#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly githubRepository='zyedidia/eget'
readonly binaryName='eget'
readonly versionArgument='--version'
readonly downloadUrlTemplate='https://github.com/${githubRepository}/releases/download/v${version}/${name}-${version}-linux_${architecture}.tar.gz'
readonly binaryPathInArchiveTemplate='${name}-${version}-linux_${architecture}/${binaryName}'
readonly binaryTargetFolder='/usr/local/bin'
readonly name="${githubRepository##*/}"
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
check_curl_envsubst_file_tar_installed() {
    declare -a requiredAptPackagesMissing=()
    if ! [ -r '/etc/ssl/certs/ca-certificates.crt' ]; then
        requiredAptPackagesMissing+=('ca-certificates')
    fi
    if ! command -v curl >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('curl')
    fi
    if ! command -v envsubst >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('gettext-base')
    fi
    if ! command -v file >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('file')
    fi
    if ! command -v tar >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('tar')
    fi
    declare -i requiredAptPackagesMissingCount=${#requiredAptPackagesMissing[@]}
    if [ $requiredAptPackagesMissingCount -gt 0 ]; then
        apt_get_update
        apt_get_checkinstall "${requiredAptPackagesMissing[@]}"
        apt_get_cleanup
    fi
}
curl_check_url() {
    local url=$1
    local status_code
    status_code=$(curl -s -o /dev/null -w '%{http_code}' "$url")
    if [ "$status_code" -ne 200 ] && [ "$status_code" -ne 302 ]; then
        echo "Failed to download '$url'. Status code: $status_code."
        return 1
    fi
}
curl_download_stdout() {
    local url=$1
    curl \
        --silent \
        --location \
        --output '-' \
        --connect-timeout 5 \
        "$url"
}
curl_download_untar() {
    local url=$1
    local strip=$2
    local target=$3
    local bin_path=$4
    curl_download_stdout "$url" | tar \
        -xz \
        -f '-' \
        --strip-components="$strip" \
        -C "$target" \
        "$bin_path"
}
debian_get_arch() {
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]]; then
        arch="arm64"
    elif [[ "$arch" == "x86_64" ]]; then
        arch="amd64"
    fi
    echo "$arch"
#    echo "$(dpkg --print-architecture)" --- IGNORE ---
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
github_list_releases() {
    if [ -z "$1" ]; then
        echo "Usage: list_github_releases <owner/repo>"
        return 1
    fi
    local repo="$1"
    local url="https://api.github.com/repos/$repo/releases"
    curl -s "$url" | grep -Po '"tag_name": "\K.*?(?=")' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//'
}
github_get_latest_release() {
    if [ -z "$1" ]; then
        echo "Usage: get_latest_github_release <owner/repo>"
        return 1
    fi
    github_list_releases "$1" | head -n 1
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
    check_curl_envsubst_file_tar_installed
    readonly architecture="$(debian_get_arch)"
    readonly binaryTargetPathTemplate='${binaryTargetFolder}/${binaryName}'
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(github_get_latest_release "$githubRepository")
    fi
    readonly version="${VERSION:?}"
    readonly downloadUrl="$(echo -n "$downloadUrlTemplate" | envsubst)"
    curl_check_url "$downloadUrl"
    readonly binaryPathInArchive="$(echo -n "$binaryPathInArchiveTemplate" | envsubst)"
    readonly stripComponents="$(echo -n "$binaryPathInArchive" | awk -F'/' '{print NF-1}')"
    readonly binaryTargetPath="$(echo -n "$binaryTargetPathTemplate" | envsubst)"
    curl_download_untar "$downloadUrl" "$stripComponents" "$binaryTargetFolder" "$binaryPathInArchive"
    chmod 755 "$binaryTargetPath"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
