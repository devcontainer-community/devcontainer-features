
# yoctoproject.org (yoctoproject.org)

Install "bitbake" binary

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/yoctoproject.org:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of "bitbake" to install. | string | latest |

# yoctoproject.org

## Project

- [Yocto Project / BitBake](https://github.com/openembedded/bitbake)

## Description

`bitbake` is the build tool at the heart of the Yocto Project and OpenEmbedded. It processes recipes and layer configurations to build custom embedded Linux distributions and cross-compilation toolchains. `bitbake` is also used standalone outside of a full Yocto environment.

## Installation Method

Downloaded as a source archive from the [openembedded/bitbake GitHub tags](https://github.com/openembedded/bitbake/tags), extracted to `/opt/bitbake`, and a wrapper script placed in `/usr/local/bin`.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/yoctoproject.org/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
