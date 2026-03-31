
# run-script (run-script)

Run a script from a URL or inline text during devcontainer build

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/run-script:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| url | URL of a script to download and execute. | string | - |
| script | Inline script text to execute. | string | - |

# run-script

## Project

_No upstream project — this is a utility feature._

## Description

A utility feature that runs a custom script during devcontainer build. Accepts either a URL pointing to a script to download and execute, or an inline script supplied directly as text. Exactly one of `url` or `script` must be provided.

## Installation Method

No binary is installed. The feature downloads (via `wget` or `curl`) or writes the provided script to a temporary file, then executes it with `bash`. If neither `wget` nor `curl` is available, `curl` is installed automatically via `apt`.

## Other Notes

- If both `url` and `script` are provided the feature fails with an error.
- If neither option is provided the feature exits successfully without doing anything.
- The temporary script file is removed after execution.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/run-script/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
