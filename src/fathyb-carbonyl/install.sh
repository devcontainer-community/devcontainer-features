#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly githubRepository='fathyb/carbonyl'
readonly binaryName='carbonyl'
readonly versionArgument='--version'
readonly binaryTargetFolder='/usr/local/bin'
readonly libTargetFolder='/usr/local/lib/carbonyl'
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
check_curl_envsubst_file_unzip_installed() {
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
    if ! command -v unzip >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('unzip')
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
curl_download_unzip_dir() {
    local url=$1
    local target=$2
    local strip_dir=$3
    local temp_file
    temp_file=$(mktemp --suffix='.zip')
    curl_download_stdout "$url" >| "$temp_file"
    unzip -o "$temp_file" -d "$target"
    if [ -n "$strip_dir" ] && [ -d "${target}/${strip_dir}" ]; then
        mv "${target}/${strip_dir}/"* "$target/"
        rmdir "${target}/${strip_dir}"
    fi
    rm -f "$temp_file"
}
debian_get_arch() {
    echo "$(dpkg --print-architecture)"
}
debian_get_target_arch() {
    case $(debian_get_arch) in
    amd64) echo 'amd64' ;;
    arm64) echo 'arm64' ;;
    *) echo 'unknown' ;;
    esac
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
install_chromium_runtime_deps() {
    # Deps from upstream Dockerfile: libasound2 libexpat1 libfontconfig1 libnss3
    apt_get_checkinstall libexpat1 libfontconfig1 libnss3
    # libasound2 was renamed to libasound2t64 in newer Debian/Ubuntu releases
    apt_get_update
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends libasound2t64 2>/dev/null \
        || DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends libasound2
}
install() {
    utils_check_version "$VERSION"
    check_curl_envsubst_file_unzip_installed
    install_chromium_runtime_deps
    readonly architecture="$(debian_get_target_arch)"
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(github_get_latest_release "$githubRepository")
    fi
    readonly version="${VERSION:?}"
    readonly releaseTag="$(github_get_tag_for_version "$githubRepository" "$version")"
    if [ -z "$releaseTag" ]; then
        printf >&2 '=== [ERROR] Could not find release tag for version "%s" in "%s"!\n' "$version" "$githubRepository"
        exit 1
    fi
    readonly downloadUrlTemplate='https://github.com/${githubRepository}/releases/download/${releaseTag}/carbonyl.linux-${architecture}.zip'
    readonly downloadUrl="$(echo -n "$downloadUrlTemplate" | envsubst)"
    curl_check_url "$downloadUrl"
    readonly stripDir="carbonyl-${version}"
    mkdir -p "$libTargetFolder"
    curl_download_unzip_dir "$downloadUrl" "$libTargetFolder" "$stripDir"
    chmod 755 "${libTargetFolder}/${binaryName}"
    ln -sf "${libTargetFolder}/${binaryName}" "${binaryTargetFolder}/${binaryName}"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
