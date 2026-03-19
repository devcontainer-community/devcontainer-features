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

## Notes

The `openssh-server` package is installed via `apt` and sshd is configured to
listen on the specified port (default `2222`).  An entrypoint script is added
that starts the sshd daemon automatically each time the container starts.

To connect from the host you may need to forward the port in your
`devcontainer.json`:

```json
"forwardPorts": [2222]
```
