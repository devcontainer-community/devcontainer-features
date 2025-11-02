#!/bin/bash
set -e


. ./ensure_nanolayer
ensure_nanolayer nanolayer_location "v0.0.5"

echo_banner "devcontainer.community"

echo $nanolayer_location

$nanolayer_location version


$nanolayer_location install github \
    "charmbracelet/gum" \
    --asset-url-template 'https://github.com/${Repo}/releases/download/v${Version}/${AssetName}_${Version}_Linux_${Architecture}.tar.gz' \
    --architecture-replacement "arm64 arm64" \
    --file-destination "*/gum /tmp/bin/gum" \
    --asset-name 'gum' \
    --asset-version "latest"

    # --asset-name 'gum' \
    # --version

# $nanolayer_location system

echo " (*) Done."
