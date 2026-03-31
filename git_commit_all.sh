#!/bin/sh

set -eu

echo ""
echo "Committing changes for all repositories..."
echo ""

current_dir=$(pwd)
push_after_commit=false
commit_message="Update"

for arg in "$@"; do
    if [ "$arg" = "--push" ]; then
        push_after_commit=true
    else
        commit_message="$arg"
    fi
done

case "$current_dir" in
    */support) updates_dir=${current_dir%/support} ;;
    *) updates_dir=$current_dir ;;
esac

[ -d "$updates_dir" ] || {
    echo "Error: base directory not found: $updates_dir" >&2
    exit 1
}

committed=0
unchanged=0
failed=0
found_repo=false

for repo_path in "$updates_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue
    [ -e "$repo_path/.git" ] || continue

    found_repo=true
    repo_name=$(basename "$repo_path")

    if [ -z "$(git -C "$repo_path" status --porcelain)" ]; then
        unchanged=$((unchanged + 1))
        continue
    fi

    if ! git -C "$repo_path" add -A; then
        echo "✖ $repo_name"
        echo "  Failed during git add"
        failed=$((failed + 1))
        echo ""
        continue
    fi

    commit_output=$(git -C "$repo_path" commit -m "$commit_message" 2>&1) || {
        echo "✖ $repo_name"
        echo "$commit_output" | sed 's/^/  /'
        failed=$((failed + 1))
        echo ""
        continue
    }

    echo "✔ $repo_name"
    echo "$commit_output" | sed 's/^/  /'

    if [ "$push_after_commit" = "true" ]; then
        push_output=$(git -C "$repo_path" push 2>&1) || {
            echo "  ✖ Push failed"
            echo "$push_output" | sed 's/^/    /'
            failed=$((failed + 1))
            echo ""
            continue
        }
        echo "  ✔ Pushed"
    fi

    committed=$((committed + 1))
    echo ""
done

if [ "$found_repo" = "false" ]; then
    echo "No git repositories found."
    echo ""
fi

echo "Summary: $committed committed, $unchanged unchanged, $failed failed"
echo ""
echo "Done!"