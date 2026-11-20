#!/bin/bash

set -e

source dev-container-features-test-lib

check "specified zmx version is installed" bash -c "zmx version | grep -F '0.6.0'"

reportResults
