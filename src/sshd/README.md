
# sshd (sshd)

Install OpenSSH server (sshd) and ensure it starts when the container starts

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/sshd:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| port | Port for sshd to listen on. | string | 2222 |

# OpenSSH Server (`sshd`)

## Project

- [OpenSSH Server (`sshd`)](https://www.openssh.com/)

## Description

The OpenSSH server daemon, which enables secure remote access to the container over SSH. This feature installs and configures `sshd` to start automatically when the container starts.

## Installation Method

Installed via the system APT package manager (`apt-get install openssh-server`). SSH host keys are generated at install time, and a container entrypoint script is configured to start `sshd` on container launch.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/sshd/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
