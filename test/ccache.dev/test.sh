#!/bin/bash

set -e

source dev-container-features-test-lib

check "execute command" bash -c "ccache --version | grep 'ccache'"

reportResults
