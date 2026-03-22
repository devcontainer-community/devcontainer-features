# change-devcontainer-feature

Modify an existing devcontainer feature: update install logic, fix bugs, change metadata — and bump the version.

## When to Use

Use this skill when an issue or request involves changing an existing feature (bug fix, install method update, description change, dependency update, etc.). Do **not** use this for creating a new feature from scratch — use `create-devcontainer-feature` for that.

## Critical Rule: Always Bump the Version

**Every change to a feature MUST include a version bump.** No exceptions.

- **Patch bump** (default): `1.0.0` → `1.0.1` — for bug fixes, minor install script changes, documentation fixes, dependency updates
- **Minor bump**: `1.0.0` → `1.1.0` — for new options, significant behavior changes, new capabilities
- **Major bump**: `1.0.0` → `2.0.0` — for breaking changes (e.g., different binary name, removed options, changed default behavior)

Use a **patch bump** unless the issue explicitly requests or the change clearly warrants a minor or major bump.

## Step 1 — Identify the Feature

Determine which feature to modify from the issue description. The feature `id` matches the directory name under `src/`.

Read the existing files to understand the current state:
- `src/<FEATURE_ID>/devcontainer-feature.json` — current version, options, metadata
- `src/<FEATURE_ID>/install.sh` — current install logic
- `src/<FEATURE_ID>/NOTES.md` — current documentation
- `test/<FEATURE_ID>/test.sh` — current tests

## Step 2 — Make the Requested Changes

Apply the changes described in the issue. Common change types:

- **Bug fix in install.sh** — fix download URL, architecture mapping, error handling, etc.
- **Update install method** — e.g., switch from curl to gh release
- **Update metadata** — description, name, options in `devcontainer-feature.json`
- **Update documentation** — `NOTES.md` content
- **Update tests** — fix or improve `test.sh` assertions
- **Update helper functions** — copy latest versions from https://github.com/devcontainer-community/shell-snippets

When modifying `install.sh`:
- Keep helper functions verbatim from the shell-snippets repo
- Only customize the feature-specific parts (repository, binary name, URL template, architecture mappings)
- Preserve the required header (`set -o` flags) and footer (`echo_banner` + install call)
- Ensure the executable bit is preserved: run `chmod +x` and `git update-index --chmod=+x` if the file is recreated

## Step 3 — Bump the Version

Update the version in **both** locations:

### 3a. `src/<FEATURE_ID>/devcontainer-feature.json`

Increment the `"version"` field:

```json
{
    "version": "1.0.1"
}
```

### 3b. Root `README.md`

Find the feature's row in the table and update the version in the last column:

```
| [feature-name](...) | `binary` — description | install-method | 1.0.1 |
```

**Both files must have the same version.** If they are out of sync before your change, align them to the new bumped version.

## Step 4 — Update Tests if Needed

If the change affects the binary name, version output format, or install location, update `test/<FEATURE_ID>/test.sh` accordingly.

If the change is purely a bug fix in install logic and the test already verifies the binary works, the test likely needs no changes.

## Step 5 — Validate

1. Verify `devcontainer-feature.json` is valid JSON and the version was bumped
2. Verify the version in `README.md` matches the version in `devcontainer-feature.json`
3. Verify `install.sh` still has correct shebang, `set -o` flags, and the executable bit
4. Verify `test.sh` still sources `dev-container-features-test-lib` and calls `reportResults`
5. Run CI tests via GitHub Actions — the test workflow automatically picks up changed features on a PR:
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i debian:latest .`
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i ubuntu:latest .`
   - `devcontainer features test --skip-scenarios -f <FEATURE_ID> -i mcr.microsoft.com/devcontainers/base:ubuntu .`

## Checklist

- [ ] Changes applied as described in the issue
- [ ] Version bumped in `src/<ID>/devcontainer-feature.json` (patch unless stated otherwise)
- [ ] Version bumped in root `README.md` (same version, correct row)
- [ ] Both versions match
- [ ] `install.sh` executable bit preserved (if file was modified)
- [ ] Tests updated if affected by the change
- [ ] CI tests pass on all three base images
