#!/bin/bash
# =============================================================================
# get-and-run.sh (dev) — fetch and run a tinstaller binary from the private
# transpara/tinstaller-releases-dev prerelease repo.
#
# DevReleases are GitHub *prereleases* in a *private* repo, so this launcher
# uses the authenticated GitHub CLI (`gh`) rather than unauthenticated curl:
#   - latest version resolves via `gh release list` (prerelease-aware), and
#   - the binary downloads via `gh release download` (handles private auth).
# Stable installs use the public launcher in transpara/tinstaller-releases.
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

if ! command -v gh &>/dev/null; then
  echo "Error: 'gh' (GitHub CLI) is required to install private dev releases. https://cli.github.com/" >&2
  exit 1
fi
if ! gh auth status &>/dev/null; then
  echo "Error: 'gh' is not authenticated. Run: gh auth login" >&2
  exit 1
fi

# Resolve version: explicit --version wins; otherwise the most recent release
# (gh release list is prerelease-aware, newest first → highest -dev.N).
if [[ -n "$VERSION" ]]; then
  echo "Using requested dev version: $VERSION"
else
  VERSION="$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName')"
  if [[ -z "$VERSION" ]]; then
    echo "Error: no dev releases found in $REPO." >&2
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

ASSET="${MODE}-linux-${ARCH}"
echo "Downloading $ASSET from $REPO@$VERSION ..."
rm -f "$MODE"
gh release download "$VERSION" --repo "$REPO" --pattern "$ASSET" --output "$MODE" --clobber
chmod +x "$MODE"

echo "--------------------------------------------------"
echo "Executing: ./$MODE ${PASSTHROUGH_ARGS[*]}"
echo "--------------------------------------------------"
./"$MODE" "${PASSTHROUGH_ARGS[@]}"
