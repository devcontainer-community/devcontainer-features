#!/bin/bash

set -e

source dev-container-features-test-lib

check "install simple package with remote user" bash -c "vcpkg install vcpkg-cmake"

reportResults
