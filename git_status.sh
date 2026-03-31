#!/bin/sh
# SUPPORT SCRIPTS: Verify repositories status
# Use in development machines only
# Alias: gss='sh support/git_status.sh'

set -eu

current_dir=$(pwd)
counter=0

for repo_path in "$current_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue
    [ -e "$repo_path/.git" ] || continue

    repo_name=$(basename "$repo_path")
    status=$(git -C "$repo_path" status --porcelain)

    if [ -n "$status" ]; then
        echo "✔ '$repo_name' --- Has local changes"
        counter=$((counter + 1))
    fi
done

if [ "$counter" -eq 0 ]; then
    echo "No projects have local changes."
else
    echo ""
    echo "$counter project(s) have local changes."
fi