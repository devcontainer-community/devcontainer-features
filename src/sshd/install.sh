#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport

readonly name="sshd"

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
    apt_get_checkinstall openssh-server

    # Create SSH drop-in config directory if missing and add devcontainer config
    mkdir -p /etc/ssh/sshd_config.d
    echo "Port ${PORT}" > /etc/ssh/sshd_config.d/devcontainer.conf

    # Generate SSH host keys at install time so they are baked into the image
    ssh-keygen -A

    # Create entrypoint directory and script
    mkdir -p /usr/local/share/sshd
    cat > /usr/local/share/sshd/entrypoint.sh << 'EOF'
#!/bin/bash
# Regenerate host keys if any are missing (e.g. first start of a new container)
ssh-keygen -A 2>/dev/null || true
# Start sshd in daemon mode if it is not already running
if ! pgrep sshd > /dev/null 2>&1; then
    /usr/sbin/sshd
fi
EOF
    chmod 755 /usr/local/share/sshd/entrypoint.sh

    apt_get_cleanup
}

echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
