#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

baseUrl="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Get latest version from npm
version=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code/latest | jq -r '.version')
echo "Latest version: $version"

# Get hash
url="${baseUrl}/${version}/linux-x64/claude"
echo "Fetching hash for $url"
hash=$(nix-prefetch-url "$url" 2>/dev/null)

echo "Hash: $hash"

# Update claude-code.nix
sed -i "s|version = \".*\";|version = \"$version\";|" claude-code.nix
sed -i "s|hash = \".*\";|hash = \"sha256:$hash\";|" claude-code.nix

echo "Updated claude-code.nix to version $version"
