#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly githubRepository='openembedded/bitbake'
readonly binaryName='bitbake'
readonly versionArgument='--version'
readonly installDir='/opt/bitbake'
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
check_curl_file_tar_installed() {
    declare -a requiredAptPackagesMissing=()
    if ! [ -r '/etc/ssl/certs/ca-certificates.crt' ]; then
        requiredAptPackagesMissing+=('ca-certificates')
    fi
    if ! command -v curl >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('curl')
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
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
bitbake_list_versions() {
    curl -s "https://api.github.com/repos/${githubRepository}/tags?per_page=100" \
        | grep -Po '"name": "yocto-\K[0-9]+\.[0-9]+\.[0-9]+(?=")'
}
bitbake_get_latest_version() {
    bitbake_list_versions | head -n 1
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
    check_curl_file_tar_installed
    apt_get_checkinstall python3 locales
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(bitbake_get_latest_version)
    fi
    readonly version="${VERSION:?}"
    readonly downloadUrl="https://github.com/${githubRepository}/archive/refs/tags/yocto-${version}.tar.gz"
    curl_check_url "$downloadUrl"
    mkdir -p "${installDir}"
    curl_download_stdout "$downloadUrl" | tar -xz -f '-' --strip-components=1 -C "${installDir}"
    printf '#!/bin/bash\nexec %s/bin/%s "$@"\n' "${installDir}" "${binaryName}" \
        > "${binaryTargetFolder}/${binaryName}"
    chmod 755 "${binaryTargetFolder}/${binaryName}"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
