#!/bin/bash

set -e

source dev-container-features-test-lib

check "gcc installed" bash -c "gcc --version | grep 'gcc'"
check "g++ installed" bash -c "g++ --version | grep 'g++'"
check "make installed" bash -c "make --version | grep -i 'make'"

reportResults
