#!/bin/bash

set -e

source dev-container-features-test-lib

check "cmake installed" bash -c "cmake --version | grep 'cmake'"
check "ninja installed" bash -c "ninja --version"
check "gdb installed" bash -c "gdb --version | grep 'GNU'"
check "valgrind installed" bash -c "valgrind --version | grep 'valgrind'"
check "ccache installed" bash -c "ccache --version | grep 'ccache'"
check "cppcheck installed" bash -c "cppcheck --version | grep 'Cppcheck'"
check "clang-format installed" bash -c "clang-format --version | grep 'clang-format'"
check "clang-tidy installed" bash -c "clang-tidy --version | grep 'LLVM'"

reportResults
