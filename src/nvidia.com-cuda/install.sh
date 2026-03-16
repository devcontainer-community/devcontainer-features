#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name='cuda'
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
get_distro_codename() {
    local distro
    local version_id
    distro="$(. /etc/os-release && echo "$ID")"
    version_id="$(. /etc/os-release && echo "$VERSION_ID" | tr -d '.')"
    echo "${distro}${version_id}"
}
get_cuda_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  echo 'x86_64' ;;
        aarch64) echo 'sbsa' ;;
        *)
            printf >&2 '=== [ERROR] Unsupported architecture: %s\n' "$arch"
            exit 1
            ;;
    esac
}
utils_check_version() {
    local version=$1
    if ! [[ "${version:-}" =~ ^(latest|[0-9]+\.[0-9]+)$ ]]; then
        printf >&2 '=== [ERROR] Option "version" (value: "%s") is not "latest" or a valid CUDA version format "X.Y" (e.g. "12.6")!\n' \
            "$version"
        exit 1
    fi
}
install() {
    utils_check_version "$VERSION"
    apt_get_checkinstall wget ca-certificates
    local distro
    local arch
    local keyring_url
    local keyring_deb
    local package_name
    distro="$(get_distro_codename)"
    arch="$(get_cuda_arch)"
    # cuda-keyring version: update when NVIDIA publishes a newer keyring package
    # See https://developer.download.nvidia.com/compute/cuda/repos/ for available versions
    readonly cuda_keyring_version='1.1-1'
    keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/${distro}/${arch}/cuda-keyring_${cuda_keyring_version}_all.deb"
    keyring_deb="/tmp/cuda-keyring_${cuda_keyring_version}_all.deb"
    echo "Downloading CUDA keyring from: ${keyring_url}"
    wget -q -O "${keyring_deb}" "${keyring_url}"
    dpkg -i "${keyring_deb}"
    rm -f "${keyring_deb}"
    apt-get update -y
    if [ "${VERSION}" = 'latest' ]; then
        package_name='cuda-toolkit'
    else
        local version_normalized
        version_normalized="$(echo "${VERSION}" | tr '.' '-')"
        package_name="cuda-toolkit-${version_normalized}"
    fi
    echo "Installing package: ${package_name}"
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests \
        --option 'Debug::pkgProblemResolver=true' \
        --option 'Debug::pkgAcquire::Worker=1' \
        "${package_name}"
    # Add /usr/local/cuda/bin to PATH for interactive shells
    echo 'export PATH="/usr/local/cuda/bin${PATH:+:${PATH}}"' > /etc/profile.d/cuda.sh
    chmod 644 /etc/profile.d/cuda.sh
    # Symlink nvcc into a standard PATH location so it is available immediately
    # (e.g. for non-interactive shells and devcontainer feature tests)
    if [ -f /usr/local/cuda/bin/nvcc ]; then
        ln -sf /usr/local/cuda/bin/nvcc /usr/local/bin/nvcc
    fi
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing ${name}..."
install "$@"
echo "(*) Done!"
