#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly dockerRepository='amir20/dozzle'
readonly binaryName='dozzle'
readonly binaryTargetFolder='/usr/local/bin'
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
check_curl_tar_installed() {
    declare -a requiredAptPackagesMissing=()
    if ! [ -r '/etc/ssl/certs/ca-certificates.crt' ]; then
        requiredAptPackagesMissing+=('ca-certificates')
    fi
    if ! command -v curl >/dev/null 2>&1; then
        requiredAptPackagesMissing+=('curl')
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
debian_get_arch() {
    echo "$(dpkg --print-architecture)"
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
dockerhub_get_token() {
    local repo="$1"
    curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
        | grep -Po '"token":"\K[^"]+'
}
dockerhub_get_arch_digest() {
    local repo="$1"
    local tag="$2"
    local arch="$3"
    local token="$4"
    local manifest
    manifest=$(curl -s \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json" \
        "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" \
        | tr -d ' \n\t')
    echo "$manifest" \
        | grep -oP '"digest":"sha256:[a-f0-9]+","size":\d+,"platform":\{"architecture":"'"$arch"'"' \
        | grep -oP 'sha256:[a-f0-9]+'
}
dockerhub_get_binary_layer_digest() {
    local repo="$1"
    local arch_digest="$2"
    local token="$3"
    local arch_manifest
    arch_manifest=$(curl -s \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
        "https://registry-1.docker.io/v2/${repo}/manifests/${arch_digest}" \
        | tr -d ' \n\t')
    local config_digest
    config_digest=$(echo "$arch_manifest" \
        | grep -oP '"config":\{"[^}]+\}' \
        | grep -oP '"digest":"sha256:\K[a-f0-9]+')
    echo "$arch_manifest" \
        | grep -oP '"digest":"sha256:[a-f0-9]+"' \
        | grep -oP 'sha256:[a-f0-9]+' \
        | grep -v "sha256:${config_digest}" \
        | tail -1
}
dockerhub_download_binary_layer() {
    local repo="$1"
    local layer_digest="$2"
    local token="$3"
    local target_dir="$4"
    curl -sL \
        --connect-timeout 30 \
        -H "Authorization: Bearer $token" \
        "https://registry-1.docker.io/v2/${repo}/blobs/${layer_digest}" \
        | tar -xz -C "$target_dir" "$binaryName"
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
    check_curl_tar_installed
    local tag
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        tag='latest'
    else
        tag="v${VERSION}"
    fi
    readonly architecture="$(debian_get_arch)"
    echo "Fetching dozzle ${tag} for ${architecture}..."
    local token
    token="$(dockerhub_get_token "$dockerRepository")"
    if [ -z "$token" ]; then
        printf >&2 '=== [ERROR] Could not obtain Docker Hub auth token!\n'
        exit 1
    fi
    local arch_digest
    arch_digest="$(dockerhub_get_arch_digest "$dockerRepository" "$tag" "$architecture" "$token")"
    if [ -z "$arch_digest" ]; then
        printf >&2 '=== [ERROR] Could not find image manifest for architecture "%s" and tag "%s"!\n' "$architecture" "$tag"
        exit 1
    fi
    local layer_digest
    layer_digest="$(dockerhub_get_binary_layer_digest "$dockerRepository" "$arch_digest" "$token")"
    if [ -z "$layer_digest" ]; then
        printf >&2 '=== [ERROR] Could not find binary layer digest!\n'
        exit 1
    fi
    dockerhub_download_binary_layer "$dockerRepository" "$layer_digest" "$token" "$binaryTargetFolder"
    chmod 755 "${binaryTargetFolder}/${binaryName}"
}
echo_banner "devcontainer.community"
echo "Installing $binaryName..."
install "$@"
echo "(*) Done!"
