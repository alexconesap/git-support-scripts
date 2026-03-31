#!/bin/sh
# Deploy repositories listed in .repos
# File format:
#   repo_url|local_directory|group
#
# Rules for the "group" field:
# - group is optional; default is "base"
# - "base" repos are always cloned
# - any other group is cloned only if passed as --<group>
#
# This allows you to organize repositories into groups and clone only the ones you need for a specific task or local project, while always ensuring the "base" repositories are available.
#
# Examples:
#
# Given a .repos file with the following content:
# 
#   https://github.com/example/repo1.git|repo1_dest_folder|base
#   https://github.com/example/repo2.git|repo2_dest_folder|extra
#   https://github.com/example/repo3.git|repo3_dest_folder|whatever
#   https://github.com/example/repo4.git|repo4_dest_folder|andever
#   https://github.com/example/repo5.git|repo5_dest_folder|andever
#
#   # Clones only the repos with the "base" group (default)
#   ./support/git_clone.sh
#
#   # Clones the "base" group and the "extra" group repos
#   ./support/git_clone.sh --extra
#
#   # Clones both "base", "whatever", and "andever" groups repos
#   ./support/git_clone.sh --whatever --andever

set -eu

full_line() {
    printf '%s\n' "--------------------------------------------------------------------------------"
}

trim() {
    # POSIX-safe trim of leading/trailing whitespace
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

has_group_flag() {
    # $1 = group name
    group_name=$1
    for enabled_group in $selected_groups; do
        [ "$enabled_group" = "$group_name" ] && return 0
    done
    return 1
}

clone_packages_repo() {
    # $1 = repo url
    # $2 = local directory
    repo_url=$1
    repo_dir=$2
    full_dir="${main_dir}/${repo_dir}"

    if [ -d "$full_dir" ]; then
        printf '• %s already exists, skipping\n' "$repo_dir"
        return 0
    fi

    printf '• Cloning %s\n' "$repo_dir"
    git clone "$repo_url" "$full_dir"
}

full_line
echo "Cloning package repositories"
echo "  Usage: $0 [--group1] [--group2] ..."
full_line

current_dir=$(pwd)

case "$current_dir" in
    */support) main_dir=${current_dir%/support} ;;
    *) main_dir=$current_dir ;;
esac

repos_file="${main_dir}/.repos"

if [ ! -f "$repos_file" ]; then
    printf 'Error: .repos file not found at %s\n' "$repos_file" >&2
    exit 1
fi

selected_groups=""

for arg in "$@"; do
    case "$arg" in
        --*)
            group_name=${arg#--}
            if [ -z "$group_name" ]; then
                printf 'Warning: ignoring empty group flag: %s\n' "$arg" >&2
                continue
            fi
            selected_groups="${selected_groups} ${group_name}"
            ;;
        *)
            printf 'Warning: ignoring unknown argument: %s\n' "$arg" >&2
            ;;
    esac
done

while IFS='|' read -r repo_url repo_dir repo_group extra_field; do
    # Ignore malformed lines with extra separators
    [ -n "${extra_field:-}" ] && {
        echo "Warning: skipping invalid line in .repos (too many fields)" >&2
        continue
    }

    repo_url=$(trim "${repo_url:-}")
    repo_dir=$(trim "${repo_dir:-}")
    repo_group=$(trim "${repo_group:-}")

    # Skip empty lines and comments
    [ -z "$repo_url" ] && continue
    case "$repo_url" in
        \#*) continue ;;
    esac

    if [ -z "$repo_dir" ]; then
        printf 'Warning: skipping invalid line, missing local directory for URL: %s\n' "$repo_url" >&2
        continue
    fi

    [ -z "$repo_group" ] && repo_group="base"

    if [ "$repo_group" = "base" ] || has_group_flag "$repo_group"; then
        clone_packages_repo "$repo_url" "$repo_dir"
    fi
done < "$repos_file"

echo "Done!"