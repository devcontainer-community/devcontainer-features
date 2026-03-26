
# yoctoproject.org/bitbake (yoctoproject.org-bitbake)

Install "bitbake" build tool for the Yocto Project

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/yoctoproject.org-bitbake:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of "bitbake" to install. | string | latest |

# yoctoproject.org/bitbake

## Project

- [BitBake](https://github.com/openembedded/bitbake)

## Description

BitBake is a generic task execution engine for the Yocto Project and OpenEmbedded that allows shell and Python tasks to be run efficiently and in parallel while working within complex inter-task dependency constraints. It is the build tool at the core of the Yocto Project's embedded Linux build system.

## Installation Method

Downloaded as a source tarball from [github.com/openembedded/bitbake](https://github.com/openembedded/bitbake) (tags in the form `yocto-X.Y.Z`) and extracted to `/opt/bitbake`, with wrapper scripts placed in `/usr/local/bin`.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/yoctoproject.org-bitbake/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
