
# vcpkg.io (vcpkg.io)

Install vcpkg C/C++ package manager

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/vcpkg.io:1": {}
}
```



# vcpkg.io

## Project

- [vcpkg](https://vcpkg.io)

## Description

An open-source C/C++ package manager by Microsoft that simplifies acquiring and building open-source libraries. vcpkg integrates with CMake and MSBuild and supports thousands of packages across Windows, Linux, and macOS.

## Installation Method

Clones the official [microsoft/vcpkg](https://github.com/microsoft/vcpkg) repository to `/usr/local/share/vcpkg` and runs the `bootstrap-vcpkg.sh` script. The `vcpkg` binary is symlinked to `/usr/local/bin/vcpkg`.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/vcpkg.io/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
