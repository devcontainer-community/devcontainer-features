
# nixos.org (nixos.org)

Install "nix" binary.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/nixos.org:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Currently unused. | string | latest |
| extra_options | Extra options to pass to the installer. | string | --init none |

# Nix

## Project

- [Nix](https://nixos.org/nix/)

## Description

A purely functional package manager and build system. Nix enables reproducible and declarative package management, allowing multiple versions of the same package to coexist without conflicts.

## Installation Method

Installed via the [Determinate Systems Nix installer](https://install.determinate.systems/nix): `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh`.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/nixos.org/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
