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
