#!/usr/bin/env bash
#
# Download the prebuilt macstrap TUI binary from the latest GitHub Release and
# install it to ~/.local/bin, checksum-verified. Best-effort by design: the
# shell engine (bin/macstrap) is the guaranteed path, so this may fail (no
# release yet, offline) without breaking a first install.
#
#   scripts/install-binary.sh
#
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-XavierAgostino/macstrap}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$(uname -m)" in
  arm64 | aarch64) arch=arm64 ;;
  x86_64 | amd64) arch=amd64 ;;
  *)
    echo "install-binary: unsupported architecture $(uname -m)" >&2
    exit 1
    ;;
esac

asset="macstrap_${os}_${arch}.tar.gz"
base="https://github.com/$REPO_SLUG/releases/latest/download"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if ! curl -fsSL -o "$tmp/$asset" "$base/$asset"; then
  echo "install-binary: no prebuilt binary available for $os/$arch yet." >&2
  exit 1
fi
curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"

# Verify the archive against the published checksum before trusting it.
(
  cd "$tmp"
  grep " ${asset}\$" checksums.txt | shasum -a 256 -c -
) || {
  echo "install-binary: checksum verification failed for $asset" >&2
  exit 1
}

tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$BIN_DIR"
install -m 0755 "$tmp/macstrap" "$BIN_DIR/macstrap"

echo "Installed macstrap -> $BIN_DIR/macstrap"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: add $BIN_DIR to your PATH to run 'macstrap' directly." ;;
esac
