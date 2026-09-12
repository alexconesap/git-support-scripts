#!/bin/sh
# SUPPORT SCRIPTS: Verify repositories status
# Use in development machines only
# Alias: gss='sh support/git_status.sh'

set -eu

. "$(dirname -- "$0")/common.sh"

current_dir=$(pwd)
counter=0

for repo_path in "$current_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue

    if [ -e "$repo_path/.git" ]; then
        git_dir="$repo_path"
    elif [ -e "$repo_path/code/.git" ]; then
        git_dir="$repo_path/code"
    else
        continue
    fi

    repo_name=$(basename "$repo_path")
    status=$(git -C "$git_dir" status --porcelain)

    if [ -n "$status" ]; then
        msg_ok "'$repo_name' --- Has local changes"
        counter=$((counter + 1))
    fi
done

if [ "$counter" -eq 0 ]; then
    msg_dim "No projects have local changes."
else
    echo ""
    msg_info "$counter project(s) have local changes."
fi