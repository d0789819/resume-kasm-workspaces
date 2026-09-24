#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF

Description:
  Install Visual Studio Code extensions.

Usage:
  bash $0 <extension_directory>

Example:
  bash $0 ./vsix

Help:
  bash $0 --help[-h]
EOF
  exit 0
}

# bash pip_download.sh --help[-h]
if [ $# -lt 1 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  show_help
fi

TARGET_DIR="$1"

# Current directory
if [ "$TARGET_DIR" == "." ]; then
  TARGET_DIR="$(pwd)"
fi

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo -e "\nError:\n  Directory '$TARGET_DIR' doesn't exist." >&2
  exit 1
fi

# Find all *.vsix in the directory
VSIX_FILES=("$TARGET_DIR"/*.vsix)

# If there are no *.vsix in the directory
if [ ${#VSIX_FILES[@]} -eq 0 ]; then
  echo -e "\nError:\n  No *.vsix found in '$TARGET_DIR'."
  exit 0
fi

# Install all *.vsix
for vsix in "${VSIX_FILES[@]}"; do
  echo
  code --install-extension "$vsix"
done

echo -e "\nAll extensions in '$TARGET_DIR' have been installed."
