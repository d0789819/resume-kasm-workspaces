#!/usr/bin/env bash
set -euo pipefail

if ! command -v pip >/dev/null 2>&1; then
  echo -e "\nError:\n  'pip' not found in PATH.\n\nPlease install pip." >&2
  exit 2
fi

show_help() {
  cat <<EOF

Description:
  Download Python packages and their dependencies.

Usage:
  bash $0 <package_name>[==<package_version>] [--dest <download_destination>] [--python-version <python_version>]

Example:
  bash $0 numpy==2.2.6 --dest ./numpy --python-version 3.10

Help:
  bash $0 --help[-h]
EOF
  exit 0
}

# bash pip_download.sh --help[-h]
if [ $# -lt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_help
fi

PACKAGE=""
DEST=""
OVERRIDE_PY=""
# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --dest)
      shift
      DEST="$1"
      shift
      ;;
    --python-version)
      shift
      OVERRIDE_PY="$1"
      shift
      ;;
    -*)
      echo -e "\nUnknown Option: $1" >&2
      exit 2
      ;;
    *)
      if [ -z "$PACKAGE" ]; then
        PACKAGE="$1"
        shift
      else
        echo -e "\nExtra Argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

# 1) Get pip debug output and extract "Compatible tags"
pip_debug_out=$(pip debug --verbose 2>/dev/null || pip debug)
# Extract lines after "Compatible tags: *" up to next empty line or EOF
compatible_block=$(printf "%s\n" "$pip_debug_out" | awk '
  BEGIN{flag=0}
  /Compatible tags:/ { flag=1; next }
  flag && NF==0 { exit }
  flag { print }
')

if [ -z "$compatible_block" ]; then
  echo -e "\nWarning:\n  Unable to find 'Compatible tags' in 'pip debug --verbose' output." >&2
  echo "pip debug output:"
  printf "%s\n" "$pip_debug_out"
  exit 3
fi

# 2) Extract the first "cp*/py*" tag from the "Compatible tags" to determine the Python version (e.g. cp310 -> 3.10, cp39 -> 3.9)
ver_tag=$(printf "%s\n" "$compatible_block" | grep -oE 'cp[0-9]{2,3}|py[0-9]{2,3}' | head -n1 || true)

if [ -z "$ver_tag" ]; then
  echo -e "\nWarning:\n  Unable to find a valid 'cp*/py*' tag." >&2
  exit 3
fi

# Extract digits from "cp*/py*"
digits=$(printf "%s\n" "$ver_tag" | sed -E 's/^[a-zA-Z]+([0-9]+)$/\1/')

# Convert to dotted form (e.g. 3.10, 3.9)
major=${digits:0:1}
minor=${digits:1}
python_version="${major}.${minor}"

# Allow override
if [ -n "$OVERRIDE_PY" ]; then
  python_version="$OVERRIDE_PY"
fi

# 3) Parse platform list (Extract last part of each tag)
platforms=$(printf "%s\n" "$compatible_block" \
  | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' \
  | awk -F- '{ print $NF }' \
  | sort -u)

# Filter out empty (Keep "any" as it's OK but often not useful for wheel selection)
platforms=$(printf "%s\n" "$platforms" | sed '/^$/d' )

if [ -z "$platforms" ]; then
  echo -e "\nWarning:\n  Unable to find any platforms." >&2
  exit 4
fi

# Convert to --platform flags
platform_flags=$(printf "%s\n" "$platforms" | sed 's/^/--platform /' | tr '\n' ' ')

# 4) Build pip download command
cmd=(pip download "$PACKAGE" --python-version "$python_version" $platform_flags --only-binary :all:)
if [ -n "$DEST" ]; then
  cmd+=(--dest "$DEST")
fi

# Output
echo -e "\n========== Parameters =========="
echo "Package: $PACKAGE"
echo "Download Destination: ${DEST:-$(pwd)}"
echo "Python Version (Derived): $python_version"
echo -e "Platforms:\n$platforms"
echo
echo "========== pip download Command =========="
printf '%q ' "${cmd[@]}"
echo
echo
"${cmd[@]}" || echo -e "\nWarning:\n  pip download failed."
echo
echo "========== pip install Command =========="
echo "pip install --no-index --find-links=${DEST:-$(pwd)} $PACKAGE"
exit 0
