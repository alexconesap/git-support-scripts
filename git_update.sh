#!/bin/sh
# Git pull from all repositories in the current directory

set -eu

echo ""
echo "Updating repositories"
echo ""

current_dir=$(pwd)

# Remove trailing /support only if it is the last component
case "$current_dir" in
    */support) updates_dir=${current_dir%/support} ;;
    *) updates_dir=$current_dir ;;
esac

updated=0
skipped=0
failed=0

for repo_path in "$updates_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue
    [ -e "$repo_path/.git" ] || continue

    repo_name=$(basename "$repo_path")

    # Check if repo has changes before pulling (optional but useful)
    status=$(git -C "$repo_path" status --porcelain)

    printf "• %s\n" "$repo_name"

    pull_output=$(git -C "$repo_path" pull 2>&1) || {
        echo "  ✖ Pull failed"
        echo "  $pull_output"
        failed=$((failed+1))
        echo ""
        continue
    }

    # Detect common cases
    case "$pull_output" in
        *"Already up to date."*)
            echo "  ✔ Already up to date"
            skipped=$((skipped+1))
            ;;
        *)
            echo "  ✔ Updated"
            updated=$((updated+1))
            ;;
    esac

    echo ""
done

echo "Summary:"
echo "  Updated: $updated"
echo "  Unchanged: $skipped"
echo "  Failed: $failed"
echo ""
echo "Done!"