#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Get latest release tag from GitHub
tag=$(curl -s https://api.github.com/repos/openai/codex/releases/latest | jq -r '.tag_name')
version=${tag#rust-v}

echo "Latest version: $version"

# Get hash (need to manually unpack to a directory since the tarball contains a single file)
url="https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz"
echo "Fetching hash for $url"
tmpdir=$(mktemp -d)
curl -sL "$url" | tar -xz -C "$tmpdir"
sri_hash=$(nix hash path "$tmpdir")
hash=$(nix hash convert --to nix32 "$sri_hash")
rm -rf "$tmpdir"

echo "Hash: $hash"

# Update codex.nix
sed -i "s|version = \".*\";|version = \"$version\";|" codex.nix
sed -i "s|hash = \".*\";|hash = \"sha256:$hash\";|" codex.nix

echo "Updated codex.nix to version $version"
