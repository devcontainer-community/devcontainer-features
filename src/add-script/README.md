
# add-script (add-script)

Add a script from a URL or inline text to /usr/local/bin during devcontainer build

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-community/devcontainer-features/add-script:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| name | Name for the script placed in /usr/local/bin. | string | - |
| url | URL of a script to download. | string | - |
| script | Inline script text to add. | string | - |

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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-community/devcontainer-features/blob/main/src/add-script/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
