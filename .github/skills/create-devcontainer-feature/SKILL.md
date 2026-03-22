# create-devcontainer-feature

Create a new devcontainer feature end-to-end: source files, test, README update, and executable permissions — ready for CI.

## When to Use

Use this skill when an issue requests adding a new CLI tool or binary as a devcontainer feature.

## Inputs

The issue description typically provides:
- **Feature name** (used to derive the directory name / feature `id`)
- **Project URL** (GitHub repo or homepage)
- **Releases URL** (GitHub Releases page)
- **Install method** (if non-default)
- **Any special notes** (e.g., extra config, service setup)

## Step 1 — Determine Feature Name (`id`)

Derive the feature directory name (which is also the `id` in `devcontainer-feature.json`).

**Priority order:**
1. **Domain-style** — preferred when the project has a well-known website (e.g., `starship.rs`, `chezmoi.io`, `deno.com`, `atuin.sh`)
2. **Owner-project** — when the project name alone is ambiguous (e.g., `charmbracelet-gum`, `schpet-linear-cli`). Use hyphens, not slashes.
3. **Plain name** — fallback for widely recognized tools (e.g., `bat`, `jq`, `fzf`)

The issue usually specifies or strongly implies the name. Use it as given unless it violates these conventions.

## Step 2 — Determine Install Method

Unless the issue specifies otherwise, choose the install method in this priority order:

1. **`gh release`** — project publishes pre-built Linux binaries on GitHub Releases (most common)
2. **`curl`** — project provides an official install script but no GitHub release binaries
3. **`apt`** — package is available in Debian/Ubuntu repos with no better option
4. **Last resort** — `cargo`, `bun`, `npm`, `nix` (prefer `bun install -g` over `npm install -g`)

## Step 3 — Investigate Release Assets (for `gh release` method)

Before writing `install.sh`, inspect the project's GitHub Releases page to determine:

1. **Asset naming pattern** — the exact filename template (e.g., `fzf-${version}-linux_${architecture}.tar.gz`)
2. **Archive format** — `.tar.gz`, `.zip`, or standalone binary
3. **Directory nesting** — is the binary at the archive root (strip=0) or inside a directory (strip=1+)?
4. **Architecture labels** — how the project names architectures (x86_64 vs amd64 vs x86-64, aarch64 vs arm64, etc.)
5. **Tag format** — `v1.0.0` vs `1.0.0` vs other prefix patterns
6. **Linux target triple** — some use `unknown-linux-musl`, some use `linux`, some use `Linux`

Map Debian architectures to the project's labels in `debian_get_target_arch()`:
- `amd64` → (varies: `x86_64`, `amd64`, `x86-64`)
- `arm64` → (varies: `aarch64`, `arm64`)
- `armhf` → (varies: `arm`, `armv6`, `armv7`)
- `i386` → (varies: `i686`, `x86`, `386`)

### Fallback: If You Cannot Access the Releases Page

If web access to the GitHub Releases page is blocked or unavailable:

1. **Check the issue description** — it should include a releases URL and may describe the asset naming pattern
2. **Use the GitHub API** — `curl -s https://api.github.com/repos/OWNER/REPO/releases/latest` returns JSON with all asset names listed under `assets[].name`
3. **Follow common conventions** — most Go projects use `<name>_<version>_linux_<arch>.tar.gz`, most Rust projects use `<name>-v<version>-<arch>-unknown-linux-musl.tar.gz`
4. **Ask the user** — if none of the above work, request the exact asset naming pattern, archive structure, and architecture labels

Never guess the asset naming pattern. If you cannot verify it, ask.

## Step 4 — Create Files

Create these files:

### 4a. `src/<FEATURE_ID>/devcontainer-feature.json`

```json
{
    "name": "<feature-display-name>",
    "id": "<FEATURE_ID>",
    "version": "1.0.0",
    "description": "Install \"<binary-name>\" binary",
    "documentationURL": "https://github.com/devcontainer-community/devcontainer-features/tree/main/src/<FEATURE_ID>",
    "options": {
        "version": {
            "type": "string",
            "default": "latest",
            "proposals": [
                "latest"
            ],
            "description": "Version of \"<binary-name>\" to install."
        }
    }
}
```

Notes:
- `id` MUST match the directory name exactly
- `name` can be human-friendly (e.g., `"AWS CLI"`) but often matches `id`
- `version` starts at `"1.0.0"` for new features
- Add `"installsAfter"` only if there is a real dependency on another feature

### 4b. `src/<FEATURE_ID>/install.sh`

Use `src/fzf/install.sh` as the **canonical template** for `gh release` features.

Copy helper functions **verbatim** — ideally sourced from https://github.com/devcontainer-community/shell-snippets. The functions to include:

- `apt_get_update`, `apt_get_checkinstall`, `apt_get_cleanup`
- `check_curl_envsubst_file_tar_installed`
- `curl_check_url`, `curl_download_stdout`, `curl_download_untar`
- `debian_get_arch`, `debian_get_target_arch`
- `echo_banner`
- `github_list_releases`, `github_get_latest_release`, `github_get_tag_for_version`
- `utils_check_version`

**Only customize these parts:**
- `readonly githubRepository='owner/repo'`
- `readonly binaryName='...'`
- `readonly versionArgument='--version'`
- `debian_get_target_arch()` case mappings (per Step 3)
- `downloadUrlTemplate` (exact asset naming pattern from Step 3)
- `binaryPathInArchive` (path inside the archive, from Step 3)

**Required header (all install.sh files):**
```bash
#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
```

**Required footer (all install.sh files):**
```bash
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
```

### `apt` install method template (reference: `src/jq/install.sh`)

```bash
#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="<PACKAGE_NAME>"
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
apt_get_checkinstall() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests --option 'Debug::pkgProblemResolver=true' --option 'Debug::pkgAcquire::Worker=1' "$@"
    fi
}
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
install() {
    apt_get_checkinstall <PACKAGE_NAME>
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
```

### `curl` (official install script) template (reference: `src/bun.sh/install.sh`)

```bash
#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly name="<TOOL_NAME>"
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
apt_get_checkinstall() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests --option 'Debug::pkgProblemResolver=true' --option 'Debug::pkgAcquire::Worker=1' "$@"
    fi
}
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
install() {
    apt_get_checkinstall curl ca-certificates  # add unzip if needed
    # For user-level install (installs to $HOME): use su $_REMOTE_USER -c "..."
    # For system-level install (installs to /usr/local): run directly
    su $_REMOTE_USER -c "curl -fsSL <INSTALL_SCRIPT_URL> | bash"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
```

Notes for curl method:
- Use `su $_REMOTE_USER -c "..."` when the tool installs to the user's HOME directory
- Run directly (no `su`) when the tool installs to a system path like `/usr/local`
- If VERSION is supported, check for `latest` and resolve it, then pass to the install script (see `src/deno.com/install.sh` for an example)

### `cargo` install method template (reference: `src/jnsahaj-lumen/install.sh`)

```bash
#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly cratesPackage='<CRATE_NAME>'
readonly binaryName='<BINARY_NAME>'
readonly binaryTargetFolder='/usr/local/bin'
readonly name='<DISPLAY_NAME>'
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
apt_get_checkinstall() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests --option 'Debug::pkgProblemResolver=true' --option 'Debug::pkgAcquire::Worker=1' "$@"
    fi
}
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
utils_check_version() {
    local version=$1
    if ! [[ "${version:-}" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        printf >&2 '=== [ERROR] Option "version" (value: "%s") is not "latest" or valid semantic version format "X.Y.Z" !\n' \
            "$version"
        exit 1
    fi
}
install() {
    utils_check_version "$VERSION"
    apt_get_checkinstall curl ca-certificates build-essential
    export RUSTUP_HOME=/usr/local/rustup
    export CARGO_HOME=/usr/local/cargo
    if ! command -v cargo >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
            sh -s -- -y --no-modify-path --default-toolchain stable
    fi
    export PATH=/usr/local/cargo/bin:$PATH
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        cargo install "$cratesPackage"
    else
        cargo install "$cratesPackage" --version "$VERSION"
    fi
    readonly binaryTargetPath="${binaryTargetFolder}/${binaryName}"
    ln -sf /usr/local/cargo/bin/"$binaryName" "$binaryTargetPath"
    chmod 755 "$binaryTargetPath"
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $name..."
install "$@"
echo "(*) Done!"
```

### `bun` install method template (reference: `src/critique.work/install.sh`)

Prefer `bun install -g` over `npm install -g` when both are viable.

```bash
#!/bin/bash
set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
set -o allexport
readonly binaryName='<BINARY_NAME>'
readonly binaryTargetFolder='/usr/local/bin'
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
apt_get_checkinstall() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests --option 'Debug::pkgProblemResolver=true' --option 'Debug::pkgAcquire::Worker=1' "$@"
    fi
}
apt_get_cleanup() {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
echo_banner() {
    local text="$1"
    echo -e "\e[1m\e[97m\e[41m$text\e[0m"
}
utils_check_version() {
    local version=$1
    if ! [[ "${version:-}" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        printf >&2 '=== [ERROR] Option "version" (value: "%s") is not "latest" or valid semantic version format "X.Y.Z" !\n' \
            "$version"
        exit 1
    fi
}
bun_ensure_installed() {
    if ! command -v bun >/dev/null 2>&1; then
        echo "Bun is not installed. Installing bun to /usr/local..."
        apt_get_checkinstall unzip curl ca-certificates
        export BUN_INSTALL=/usr/local
        curl -fsSL https://bun.sh/install | bash
    fi
}
install() {
    utils_check_version "$VERSION"
    export BUN_INSTALL=/usr/local
    bun_ensure_installed
    if [ "$VERSION" == 'latest' ] || [ -z "$VERSION" ]; then
        bun install -g <NPM_PACKAGE_NAME>
    else
        bun install -g "<NPM_PACKAGE_NAME>@${VERSION}"
    fi
    apt_get_cleanup
}
echo_banner "devcontainer.community"
echo "Installing $binaryName..."
install "$@"
echo "(*) Done!"
```

All helper functions should be copied verbatim. The canonical source is https://github.com/devcontainer-community/shell-snippets — check there first for the latest versions of shared functions.

### 4c. `src/<FEATURE_ID>/NOTES.md`

```markdown
# <display-name>

## Project

- [<project-name>](<project-url>)

## Description

<2-3 sentence description of what the tool does and its main use case. Use backticks around the CLI command name.>

## Installation Method

<One of these templates:>
- gh release: "Downloaded as a pre-compiled binary from the [GitHub releases page](<releases-url>) and placed in `/usr/local/bin`."
- apt: "Installed via the system APT package manager (`apt-get install <name>`)."
- curl: "Installed via the official install script."
- cargo/bun/npm: "Installed via `<package-manager> install <package>`."

## Other Notes

_No additional notes._
```

Add real notes under "Other Notes" only if there are genuinely important caveats (e.g., requires specific env vars, requires a running service, user-level vs system-level install).

### 4d. `src/<FEATURE_ID>/README.md`

Do **NOT** create this file manually. It is auto-generated by the release workflow from `devcontainer-feature.json` + `NOTES.md`.

### 4e. `test/<FEATURE_ID>/test.sh`

```bash
#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
check "execute command" bash -c "<binary-name> --version | grep '<expected-grep-pattern>'"

# Report results
reportResults
```

**Choosing the grep pattern:**
- Run the binary's `--version` (or `version`) command to see its actual output format
- Grep for a stable substring (usually the binary name or `version`)
- If `--version` is not supported, use whichever flag produces identifiable output
- For services (like sshd), test that the service binary exists and test relevant functionality

### 4f. `.github/workflows/test.yaml`

Do **NOT** modify this file. The CI workflow automatically detects new features via `src/` and `test/` directory changes.

## Step 5 — Update Root README.md

Add a new row to the feature table in `README.md` (repo root). **Maintain alphabetical order.**

Format:
```
| [<display-name>](https://github.com/devcontainer-community/devcontainer-features/tree/main/src/<FEATURE_ID>) | `<binary-name>` — <short description> | <install-method> | 1.0.0 |
```

Where `<install-method>` is one of: `gh release`, `apt`, `curl`, `cargo`, `bun`, `npm`, `nix`.

## Step 6 — Set Executable Permissions

The `install.sh` file MUST have the executable bit set. Run both:

```bash
chmod +x src/<FEATURE_ID>/install.sh
git update-index --chmod=+x src/<FEATURE_ID>/install.sh
```

## Step 7 — Validate

1. Verify `devcontainer-feature.json` is valid JSON and matches the schema
2. Verify `install.sh` has correct shebang, set -o flags, and the executable bit
3. Verify `test.sh` sources `dev-container-features-test-lib` and calls `reportResults`
4. Verify the README.md table entry is in the correct alphabetical position
5. Run CI tests via GitHub Actions — the test workflow will automatically pick up the new feature on a PR:
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i debian:latest .`
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i ubuntu:latest .`
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i mcr.microsoft.com/devcontainers/base:ubuntu .`

## Checklist

- [ ] `src/<ID>/devcontainer-feature.json` — valid JSON, correct `id`, version `1.0.0`
- [ ] `src/<ID>/install.sh` — working script, executable bit set, helper functions verbatim from template
- [ ] `src/<ID>/NOTES.md` — links to project, description, install method documented
- [ ] `test/<ID>/test.sh` — sources test lib, has at least one `check`, calls `reportResults`
- [ ] `README.md` — new row added in alphabetical order
- [ ] `src/<ID>/README.md` — NOT manually created (auto-generated)
- [ ] Executable bit set via `chmod +x` AND `git update-index --chmod=+x`
- [ ] CI tests pass on all three base images (debian, ubuntu, devcontainers/base)
