#!/bin/bash


set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]

check "sshd installed" which sshd
check "openssh version" bash -c "sshd -V 2>&1 | grep -i openssh"
check "sshd port configured" bash -c "grep -r 'Port 2222' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/"
check "sshd running" bash -c "pgrep sshd || ( mkdir -p /run/sshd && /usr/sbin/sshd && sleep 1 && pgrep sshd )"
check "sshd listening on port 2222" bash -c "ss -tln | grep ':2222'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
