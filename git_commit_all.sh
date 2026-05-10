#!/bin/sh

set -eu

. "$(dirname -- "$0")/common.sh"

msg_section "Committing changes for all repositories"

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
    msg_error "Base directory not found: $updates_dir"
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
        msg_error "$repo_name"
        msg_dim "  Failed during git add"
        failed=$((failed + 1))
        echo ""
        continue
    fi

    commit_output=$(git -C "$repo_path" commit -m "$commit_message" 2>&1) || {
        msg_error "$repo_name"
        echo "$commit_output" | sed 's/^/  /'
        failed=$((failed + 1))
        echo ""
        continue
    }

    msg_ok "$repo_name"
    echo "$commit_output" | sed 's/^/  /'

    if [ "$push_after_commit" = "true" ]; then
        push_output=$(git -C "$repo_path" push 2>&1) || {
            msg_error "  Push failed"
            echo "$push_output" | sed 's/^/    /'
            failed=$((failed + 1))
            echo ""
            continue
        }
        msg_ok "  Pushed"
    fi

    committed=$((committed + 1))
    echo ""
done

if [ "$found_repo" = "false" ]; then
    msg_warn "No git repositories found."
    echo ""
fi

msg_section "Summary"
printf '  %s%d%s committed, %s%d%s unchanged, %s%d%s failed\n' \
    "$_c_green" "$committed" "$_c_reset" \
    "$_c_gray" "$unchanged" "$_c_reset" \
    "$_c_red" "$failed" "$_c_reset"
echo ""
msg_ok "Done!"