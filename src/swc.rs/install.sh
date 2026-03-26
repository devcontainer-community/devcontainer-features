#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly githubRepository='swc-project/swc'
readonly binaryName='swc'
readonly versionArgument='--version'
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
debian_get_arch() {
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]]; then
        arch="arm64"
    elif [[ "$arch" == "x86_64" ]]; then
        arch="x64"
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
github_get_tag_for_version() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: github_get_tag_for_version <owner/repo> <version>"
        return 1
    fi
    local repo="$1"
    local _version="$2"
    local url="https://api.github.com/repos/$repo/releases"
    local escaped_version
    escaped_version="$(printf '%s' "$_version" | sed 's/\./\\./g')"
    curl -s "$url" | grep -Po '"tag_name": "\K.*?(?=")' | grep -E "^v?${escaped_version}$" | head -n 1
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
    check_curl_installed
    readonly architecture="$(debian_get_arch)"
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(github_get_latest_release "$githubRepository")
    fi
    readonly version="${VERSION:?}"
    readonly releaseTag="$(github_get_tag_for_version "$githubRepository" "$version")"
    if [ -z "$releaseTag" ]; then
        printf >&2 '=== [ERROR] Could not find release tag for version "%s" in "%s"!\n' "$version" "$githubRepository"
        exit 1
    fi
    readonly downloadUrl="https://github.com/${githubRepository}/releases/download/${releaseTag}/${binaryName}-linux-${architecture}-gnu"
    curl_check_url "$downloadUrl"
    readonly binaryTargetPath="${binaryTargetFolder}/${binaryName}"
    curl_download_stdout "$downloadUrl" >| "$binaryTargetPath"
    chmod 755 "$binaryTargetPath"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
