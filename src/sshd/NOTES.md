# OpenSSH Server (`sshd`)

## Project

- [OpenSSH Server (`sshd`)](https://www.openssh.com/)

## Description

The OpenSSH server daemon, which enables secure remote access to the container over SSH. This feature installs and configures `sshd` to start automatically when the container starts.

## Installation Method

Installed via the system APT package manager (`apt-get install openssh-server`). SSH host keys are generated at install time, and a container entrypoint script is configured to start `sshd` on container launch.

## Other Notes

_No additional notes._
