#!/bin/bash

set -e

source dev-container-features-test-lib

check "test-backtick script exists" test -f /usr/local/bin/test-backtick
check "test-backtick script is executable" test -x /usr/local/bin/test-backtick
check "test-backtick script contains verbatim backtick" grep -qF '`hostname`' /usr/local/bin/test-backtick

reportResults
