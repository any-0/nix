#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

baseUrl="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Get latest version from npm
version=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code/latest | jq -r '.version')
echo "Latest version: $version"

hash_for_url() {
  local url="$1"
  echo "Fetching hash for $url" >&2
  nix-prefetch-url "$url" 2>/dev/null | tail -n 1
}

replace_in_file() {
  local file="$1"
  local expr="$2"
  local tmp
  tmp="$(mktemp)"
  sed "$expr" "$file" > "$tmp"
  mv "$tmp" "$file"
}

linux_url="${baseUrl}/${version}/linux-x64/claude"
darwin_aarch64_url="${baseUrl}/${version}/darwin-arm64/claude"

linux_hash=$(hash_for_url "$linux_url")
darwin_aarch64_hash=$(hash_for_url "$darwin_aarch64_url")

echo "Linux hash: $linux_hash"
echo "Darwin aarch64 hash: $darwin_aarch64_hash"

# Update claude-code.nix
replace_in_file claude-code.nix "s|version = \".*\";|version = \"$version\";|"
replace_in_file claude-code.nix "s|linuxHash = \".*\";|linuxHash = \"sha256:$linux_hash\";|"
replace_in_file claude-code.nix "s|darwinAarch64Hash = \".*\";|darwinAarch64Hash = \"sha256:$darwin_aarch64_hash\";|"

echo "Updated claude-code.nix to version $version"
