#!/bin/bash
set -e
. ./ensure_nanolayer
ensure_nanolayer nanolayer_location "v0.0.3"


$nanolayer_location install github \
    charmbracelet/gum \
    --asset-url-template 'https://github.com/${Repo}/releases/download/v${Version}/${AssetName}_${Version}_Linux_${Architecture}.tar.gz' \
    --architecture-replacement "arm64 arm64" \
    --file-destination "*/gum /usr/local/bin/gum"

    # --asset-name 'gum' \

# $nanolayer_location system
