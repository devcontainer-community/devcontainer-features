# add-script

## Project

_No upstream project — this is a utility feature._

## Description

A utility feature that adds a custom script to `/usr/local/bin` during devcontainer build. Accepts either a URL pointing to a script to download, or an inline script supplied directly as text. The script is placed at `/usr/local/bin/<name>` and made executable, but is **not** executed during install. Exactly one of `url` or `script` must be provided along with a `name`.

## Installation Method

No binary is installed. The feature downloads (via `wget` or `curl`) or writes the provided script to `/usr/local/bin/<name>` and sets its permissions to executable (`755`). If neither `wget` nor `curl` is available, `curl` is installed automatically via `apt`.

## Other Notes

- If both `url` and `script` are provided the feature fails with an error.
- If neither `url` nor `script` is provided, or if `name` is not provided, the feature exits successfully without doing anything.
- The script is **not** executed during the devcontainer build — it is only placed at the target path for later use.
