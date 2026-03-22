#!/usr/bin/env python3
"""Generate the features table in README.md from src/*/devcontainer-feature.json files."""

import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(REPO_ROOT, "src")
README_PATH = os.path.join(REPO_ROOT, "README.md")

TABLE_START = "<!-- FEATURES_TABLE_START -->"
TABLE_END = "<!-- FEATURES_TABLE_END -->"

REPO_URL = "https://github.com/devcontainer-community/devcontainer-features"


def _get_install_fn_body(content: str) -> str:
    """Extract the body of the install() function from a shell script."""
    match = re.search(r"^install\(\)\s*\{(.+?)^}", content, re.MULTILINE | re.DOTALL)
    return match.group(1) if match else content


def detect_install_method(install_sh_path: str) -> str:
    """Detect the primary install method from an install.sh file."""
    if not os.path.exists(install_sh_path):
        return "?"
    with open(install_sh_path, "r", encoding="utf-8") as f:
        content = f.read()

    # githubRepository variable indicates a GitHub release download
    if re.search(r"\bgithubRepository\b", content):
        return "gh release"

    # For remaining checks, prefer the install() function body if available
    body = _get_install_fn_body(content)

    if re.search(r"nix profile install|nix-env\b|nix --extra|\bnixBin\b.*profile", body):
        return "nix"
    if re.search(r"\bcargo install\b", body):
        return "cargo"
    if re.search(r"\bbun install\b", body):
        return "bun"
    if re.search(r"\bnpm install\b|\bnpm i\b", body):
        return "npm"
    if re.search(r"\bpip3? install\b", body):
        return "pip"
    if re.search(r"\bcurl\b|\bwget\b", body):
        return "curl"
    if re.search(r"\bapt-get install\b|\bapt_get_checkinstall\b", body):
        return "apt"
    return "?"


def get_features() -> list[dict]:
    """Read all features from src/*/devcontainer-feature.json."""
    features = []
    for feature_dir in sorted(os.listdir(SRC_DIR)):
        feature_path = os.path.join(SRC_DIR, feature_dir)
        if not os.path.isdir(feature_path):
            continue
        json_path = os.path.join(feature_path, "devcontainer-feature.json")
        if not os.path.exists(json_path):
            continue
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        install_sh = os.path.join(feature_path, "install.sh")
        install_method = detect_install_method(install_sh)

        features.append(
            {
                "dir": feature_dir,
                "name": data.get("name", feature_dir),
                "description": data.get("description", ""),
                "version": data.get("version", "?"),
                "install_method": install_method,
            }
        )
    return features


def generate_table(features: list[dict]) -> str:
    """Generate a markdown table from the features list."""
    lines = [
        "| Feature | Description | Install method | Version |",
        "| ------- | ----------- | -------------- | ------- |",
    ]
    for f in features:
        src_link = f"{REPO_URL}/tree/main/src/{f['dir']}"
        name_cell = f"[{f['name']}]({src_link})"
        lines.append(
            f"| {name_cell} | {f['description']} | {f['install_method']} | {f['version']} |"
        )
    return "\n".join(lines)


def update_readme(table: str) -> None:
    """Insert or update the features table in README.md."""
    with open(README_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    new_section = f"{TABLE_START}\n{table}\n{TABLE_END}"

    if TABLE_START in content and TABLE_END in content:
        updated = re.sub(
            re.escape(TABLE_START) + r".*?" + re.escape(TABLE_END),
            new_section,
            content,
            flags=re.DOTALL,
        )
    else:
        updated = content.rstrip() + "\n\n" + new_section + "\n"

    with open(README_PATH, "w", encoding="utf-8") as f:
        f.write(updated)


def main() -> None:
    features = get_features()
    if not features:
        print("No features found.", file=sys.stderr)
        sys.exit(1)
    table = generate_table(features)
    update_readme(table)
    print(f"Updated {README_PATH} with {len(features)} features.")


if __name__ == "__main__":
    main()
