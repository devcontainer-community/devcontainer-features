#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
# set -e


. ./ensure_nanolayer
ensure_nanolayer nanolayer_location "v0.0.5"

echo_banner "devcontainer.community"

echo $nanolayer_location

$nanolayer_location version


# $nanolayer_location install github \
#     "charmbracelet/gum" \
#     --asset-url-template 'https://github.com/${Repo}/releases/download/v${Version}/${AssetName}_${Version}_Linux_${Architecture}.tar.gz' \
#     --architecture-replacement "arm64 arm64" \
#     --file-destination "*/gum /tmp/bin/gum" \
#     --asset-name 'gum' \
#     --asset-version "latest"


# $nanolayer_location install github \
#     "astral-sh/uv" \
#     --asset-url-template 'https://github.com/${Repo}/releases/download/${Version}/${AssetName}-${Architecture}-unknown-linux-musl.tar.gz' \
#     --file-destination "*/uv /tmp/bin/uv" \
#     --file-destination "*/uvx /tmp/bin/uvx" \
#     --asset-version ${VERSION:-"latest"}

# $nanolayer_location install github \
#     "aristocratos/btop" \
#     --asset-url-template 'https://github.com/${Repo}/releases/download/v${Version}/${AssetName}-${Architecture}-linux-musl.tbz' \
#     --asset-version ${VERSION:-"latest"} \
#     --file-destination "./btop/bin/btop /tmp/local/bin/btop"

# $nanolayer_location system

echo " (*) Done."
