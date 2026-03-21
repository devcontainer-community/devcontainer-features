
# devenv.sh (devenv.sh)

Install devenv via Nix

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/devenv.sh:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of devenv to install (e.g. "2.0.4"), or "latest". | string | latest |

# devenv

## Project

- [devenv](https://devenv.sh)

## Description

A fast, declarative, reproducible, and composable developer environment tool built on Nix. `devenv` lets you define development shells, services, and scripts in a single `devenv.nix` file.

## Installation Method

Installed via the [Determinate Systems Nix installer](https://install.determinate.systems/nix) (if Nix is not already present), followed by installing `devenv` through the Nix package manager using the `devenv.sh` flake.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/devenv.sh/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
