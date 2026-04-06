#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Get latest release tag from GitHub
tag=$(curl -s https://api.github.com/repos/openai/codex/releases/latest | jq -r '.tag_name')
version=${tag#rust-v}

echo "Latest version: $version"

# Get tarball hashes for the release assets used by overlays/codex.nix.
hash_for_url() {
  local url="$1"
  echo "Fetching hash for $url" >&2
  nix store prefetch-file --json --refresh --hash-type sha256 "$url" | jq -r '.hash'
}

replace_in_file() {
  local file="$1"
  local expr="$2"
  local tmp
  tmp="$(mktemp)"
  sed "$expr" "$file" > "$tmp"
  mv "$tmp" "$file"
}

linux_url="https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz"
darwin_aarch64_url="https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-apple-darwin.tar.gz"

linux_hash=$(hash_for_url "$linux_url")
darwin_aarch64_hash=$(hash_for_url "$darwin_aarch64_url")

echo "Linux hash: $linux_hash"
echo "Darwin aarch64 hash: $darwin_aarch64_hash"

# Update codex.nix
replace_in_file codex.nix "s|version = \".*\";|version = \"$version\";|"
replace_in_file codex.nix "s|linuxHash = \".*\";|linuxHash = \"$linux_hash\";|"
replace_in_file codex.nix "s|darwinAarch64Hash = \".*\";|darwinAarch64Hash = \"$darwin_aarch64_hash\";|"

echo "Updated codex.nix to version $version"
