#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="asdf"
readonly githubRepository="asdf-vm/asdf"
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
    apt_get_checkinstall git curl ca-certificates
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        VERSION=$(github_get_latest_release "$githubRepository")
    fi
    su $_REMOTE_USER -c "git clone https://github.com/$githubRepository.git $_REMOTE_USER_HOME/.asdf --branch v$VERSION"
    apt_get_cleanup
    echo '. "$HOME/.asdf/asdf.sh"' >>"$_REMOTE_USER_HOME/.bashrc"
    echo '. "$HOME/.asdf/completions/asdf.bash"' >>"$_REMOTE_USER_HOME/.bashrc"
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
