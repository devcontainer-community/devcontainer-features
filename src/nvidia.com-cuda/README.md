
# nvidia.com/cuda (nvidia.com-cuda)

Install NVIDIA CUDA Toolkit

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/nvidia.com-cuda:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of CUDA Toolkit to install (e.g. "latest", "12.6"). | string | latest |

# NVIDIA CUDA Toolkit

## Project

- [NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)

## Description

A parallel computing platform and programming model for NVIDIA GPUs. The CUDA Toolkit includes compiler tools, libraries, and developer utilities for building GPU-accelerated applications.

## Installation Method

Installed via APT from the [official NVIDIA CUDA repository](https://developer.download.nvidia.com/compute/cuda/repos/). The CUDA keyring package is downloaded and added, then `cuda-toolkit` (or a specific versioned package) is installed.

## Other Notes

_No additional notes._


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/nvidia.com-cuda/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
