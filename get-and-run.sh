#!/bin/bash
# =============================================================================
# get-and-run.sh (dev) — fetch and run a tinstaller binary from the public
# transpara/tinstaller-releases-dev prerelease repo.
#
# DevReleases are GitHub *prereleases*, so version resolution uses the
# /releases list (newest first, prerelease-aware) instead of /releases/latest
# (which skips prereleases). Otherwise identical in spirit to the public
# launcher in transpara/tinstaller-releases.
#
# Usage:
#   get-and-run.sh <install-k3s|install-tsystem|install-control-plane> \
#                  [--version <X.Y.Z-dev.N>] [installer flags...]
# =============================================================================
set -euo pipefail

REPO="transpara/tinstaller-releases-dev"
MODE=""
VERSION=""
PASSTHROUGH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    install-k3s|install-tsystem|install-control-plane)
      MODE="$1"; shift ;;
    --version)
      VERSION="$2"; shift 2 ;;
    *)
      PASSTHROUGH_ARGS+=("$1"); shift ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "Error: no command. Usage: $0 <install-k3s|install-tsystem|install-control-plane> [--version X.Y.Z-dev.N] [flags]" >&2
  exit 1
fi

# Resolve version: explicit --version wins; otherwise the newest release
# (the /releases list is prerelease-aware and newest-first → highest -dev.N).
if [[ -n "$VERSION" ]]; then
  echo "Using requested dev version: $VERSION"
else
  if ! command -v jq &>/dev/null; then
    echo "Installing 'jq'..."
    if [ -f /etc/debian_version ]; then
      sudo apt-get update -y && sudo apt-get install -y jq
    elif [ -f /etc/redhat-release ]; then
      command -v dnf &>/dev/null && sudo dnf install -y jq || sudo yum install -y jq
    elif grep -qi suse /etc/os-release 2>/dev/null; then
      sudo zypper install -y jq
    else
      echo "Error: 'jq' is required. Install it manually or pass --version X.Y.Z-dev.N" >&2
      exit 1
    fi
  fi
  VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases" | jq -r '.[0].tag_name')
  if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    echo "Error: failed to resolve the latest dev release from ${REPO}." >&2
    exit 1
  fi
  echo "Using latest dev release: $VERSION"
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Error: unsupported architecture $ARCH" >&2; exit 1 ;;
esac

BINARY_NAME="${MODE}-linux-${ARCH}"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"

echo "Downloading $BINARY_NAME ..."
rm -f "$BINARY_NAME" "$MODE"
if curl -#LfO "$URL"; then
  mv "$BINARY_NAME" "$MODE"
  chmod +x "$MODE"
  echo "--------------------------------------------------"
  echo "Executing: ./$MODE ${PASSTHROUGH_ARGS[*]}"
  echo "--------------------------------------------------"
  ./"$MODE" "${PASSTHROUGH_ARGS[@]}"
else
  echo "Error: download failed: $URL" >&2
  exit 1
fi
