
# tmux (tmux)

Install "tmux" terminal multiplexer

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/tmux:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of "tmux" to install (e.g. "latest", "3.5a", "3.4"). | string | latest |

# tmux

## Project

- [tmux](https://github.com/tmux/tmux)

## Description

A terminal multiplexer. `tmux` lets you switch easily between several programs in one terminal, detach them (they keep running in the background), and reattach them to a different terminal.

## Installation Method

Built from source using the [GitHub releases page](https://github.com/tmux/tmux/releases) source tarball. Build dependencies (`build-essential`, `pkg-config`, `libevent-dev`, `libncurses-dev`, `bison`) are installed temporarily and cleaned up after the build.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/tmux/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
