#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 2
fi

skill="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$repo_root/skills/$skill"
manifest="$source_dir/SKILL.md"
skills_home="${COPILOT_SKILLS_HOME:-$HOME/.copilot/skills}"
destination="$skills_home/$skill"
staging="$destination.new"
backup="$destination.backup"

if [[ ! -f "$manifest" ]]; then
  echo "Skill '$skill' was not found at '$source_dir'." >&2
  exit 1
fi

first_line="$(sed -n '1p' "$manifest")"
name_line="$(sed -n '2p' "$manifest")"
if [[ "$first_line" != "---" || "$name_line" != "name: $skill" ]]; then
  echo "SKILL.md has missing or invalid frontmatter for '$skill'." >&2
  exit 1
fi

mkdir -p "$skills_home"
rm -rf -- "$staging"
cp -R -- "$source_dir" "$staging"

restore_backup() {
  if [[ -d "$backup" && ! -e "$destination" ]]; then
    mv -- "$backup" "$destination"
  fi
}
trap restore_backup ERR

if [[ -e "$destination" ]]; then
  rm -rf -- "$backup"
  mv -- "$destination" "$backup"
  mv -- "$staging" "$destination"
  rm -rf -- "$backup"
else
  mv -- "$staging" "$destination"
fi

trap - ERR
printf "Installed '%s' to '%s'.\n" "$skill" "$destination"
