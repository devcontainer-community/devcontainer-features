
# ca-certificates (ca-certificates)

Install "ca-certificates" and optionally add custom CA certificates from URLs

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/ca-certificates:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| urls | Newline-separated list of URLs to download as additional CA certificates into /usr/local/share/ca-certificates. | string | - |

# ca-certificates

## Project

- [ca-certificates](https://packages.debian.org/stable/ca-certificates)

## Description

Installs the `ca-certificates` package, which provides common CA certificates for SSL/TLS certificate verification. Optionally downloads additional custom CA certificates from specified URLs and registers them with `update-ca-certificates`.

## Installation Method

Installed via the system package manager (`apt`). Additional certificates are downloaded with `wget` or `curl` (installing `curl` if neither is available) and placed in `/usr/local/share/ca-certificates`, then registered via `update-ca-certificates`.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/ca-certificates/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
