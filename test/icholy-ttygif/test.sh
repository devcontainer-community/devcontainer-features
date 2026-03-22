#!/bin/bash


set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "execute command" bash -c "WINDOWID=1 ttygif --version | grep -E '[0-9]+\.[0-9]+\.[0-9]+'"
# Note: WINDOWID=1 is set because ttygif requires an X11 WINDOWID env var at startup,
# even for --version. Setting it to a dummy value allows version checking in headless containers.

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
