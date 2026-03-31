#!/bin/bash

set -e

source dev-container-features-test-lib

check "run-script created output file" test -f /tmp/devcontainer-run-script-test.txt
check "run-script output contains expected prefix" grep -q 'backtick_test=' /tmp/devcontainer-run-script-test.txt
check "run-script output contains non-empty value" grep -qv 'backtick_test=$' /tmp/devcontainer-run-script-test.txt

reportResults
