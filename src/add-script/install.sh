#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="add-script"

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

install() {
    # Re-read SCRIPT from the env file verbatim to prevent shell evaluation of
    # backticks: the devcontainer CLI wraps option values in double quotes in the
    # env file and then sources it, which causes bash to evaluate backticks.
    # Reading the file directly with awk avoids this evaluation.
    if [ -f ./devcontainer-features.env ]; then
        SCRIPT=$(awk '/^SCRIPT="/{sub(/^SCRIPT="/,"");v=$0;f=1;next}f{v=v"\n"$0}END{if(f){sub(/"$/,"",v);printf"%s",v}}' ./devcontainer-features.env)
    fi

    if [ -z "${NAME}" ]; then
        echo "No script name provided. Nothing to do."
        return 0
    fi

    if [ -n "${URL}" ] && [ -n "${SCRIPT}" ]; then
        printf >&2 '=== [ERROR] Both "url" and "script" options are provided. Please provide only one.\n'
        exit 1
    fi

    if [ -z "${URL}" ] && [ -z "${SCRIPT}" ]; then
        echo "No script URL or inline script provided. Nothing to do."
        return 0
    fi

    local scriptTargetPath="/usr/local/bin/${NAME}"

    if [ -n "${URL}" ]; then
        echo "Downloading script from: ${URL}"
        if command -v wget >/dev/null 2>&1; then
            wget -qO "${scriptTargetPath}" "${URL}"
        elif command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "${scriptTargetPath}" "${URL}"
        else
            apt_get_checkinstall curl ca-certificates
            apt_get_cleanup
            curl -fsSL -o "${scriptTargetPath}" "${URL}"
        fi
    else
        echo "Writing inline script to /usr/local/bin/${NAME}..."
        printf '%s' "${SCRIPT}" | tee "${scriptTargetPath}" >/dev/null
    fi

    chmod 755 "${scriptTargetPath}"
    echo "Script added at: ${scriptTargetPath}"
}

echo_banner "devcontainer.community"
echo "Running $name..."
install "$@"
echo "(*) Done!"
