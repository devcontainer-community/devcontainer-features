#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="c-cpp-dev-collection"
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
install() {
    echo "This meta-feature installs C/C++ dev tools via its dependencies."
    echo "See devcontainer-feature.json 'dependsOn' for the list of included features."
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
