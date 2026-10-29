#!/usr/bin/env bash
# Clone every repo listed in repos.yaml into ./repos/, or pull if it's already there.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/repos"

# repos.yaml uses a fixed shape: "- name: X" followed by "url: Y".
awk '/^[[:space:]]*- name:/ {name=$3} /^[[:space:]]*url:/ {print name, $2}' "$root/repos.yaml" |
while read -r name url; do
  dest="$root/repos/$name"
  if [ -d "$dest/.git" ]; then
    echo "==> $name: pulling"
    if git -C "$dest" rev-parse --verify -q HEAD >/dev/null; then
      git -C "$dest" pull --ff-only
    else
      echo "    (empty repo, nothing to pull)"
    fi
  else
    echo "==> $name: cloning"
    git clone "$url" "$dest"
  fi
done
