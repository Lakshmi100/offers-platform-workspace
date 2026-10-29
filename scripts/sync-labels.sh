#!/usr/bin/env bash
# Create or update the labels in .github/labels.yml on this repo and every repo in repos.yaml.
# Usage: ./scripts/sync-labels.sh            (all repos)
#        ./scripts/sync-labels.sh owner/repo (one repo)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -gt 0 ]; then
  targets=("$@")
else
  targets=("Lakshmi100/offers-platform-workspace")
  while read -r url; do
    targets+=("$(echo "$url" | sed -E 's#https://github.com/##; s#\.git$##')")
  done < <(awk '/^[[:space:]]*url:/ {print $2}' "$root/repos.yaml")
fi

# Emit "name<TAB>color<TAB>description" per label.
labels="$(awk '
  /^- name:/        { sub(/^- name:[[:space:]]*/, ""); name=$0 }
  /^  color:/       { sub(/^  color:[[:space:]]*/, ""); gsub(/"/, ""); color=$0 }
  /^  description:/ { sub(/^  description:[[:space:]]*/, ""); gsub(/"/, ""); print name "\t" color "\t" $0 }
' "$root/.github/labels.yml")"

for repo in "${targets[@]}"; do
  echo "==> $repo"
  while IFS=$'\t' read -r name color desc; do
    gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force >/dev/null
    echo "    $name"
  done <<< "$labels"
done
