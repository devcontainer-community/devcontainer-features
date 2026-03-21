#!/bin/bash
set -e

# Import test library from devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "execute command" bash -c "linear --version"

# Report results
reportResults
