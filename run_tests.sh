#!/bin/sh
# This script runs tests for all repositories found in the current directory that contains a 'tests' directory.
# Usage:
#   ./run_tests.sh [--clean] [folder ...]
# Options:
#   --clean: Remove existing build artifacts before running tests.
#   folder:  Optional list of library folder names to limit execution. If omitted, all repositories are tested.

set -eu

. "$(dirname -- "$0")/common.sh"

clean=0
filter=""
for arg in "$@"; do
    case "$arg" in
        --clean) clean=1 ;;
        -*) msg_error "Unknown argument: $arg"; exit 1 ;;
        *) filter="$filter $arg" ;;
    esac
done

msg_section "Running tests"
[ "$clean" -eq 1 ] && msg_info "Clean build enabled"
echo ""

current_dir=$(pwd)

case "$current_dir" in
    */support) updates_dir=${current_dir%/support} ;;
    *) updates_dir=$current_dir ;;
esac

executed=0
skipped=0
failed=0
total_tests=0
failed_list=""

for repo_path in "$updates_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue

    repo_name=$(basename "$repo_path")

    if [ -n "$filter" ]; then
        match=0
        for wanted in $filter; do
            [ "$wanted" = "$repo_name" ] && match=1 && break
        done
        [ "$match" -eq 1 ] || continue
    fi
    tests_dir="$repo_path/tests"
    run_script="$tests_dir/2_run.sh"

    msg_rule
    msg_bullet "$repo_name"
    msg_rule

    if [ ! -d "$tests_dir" ] || [ ! -f "$run_script" ]; then
        msg_dim " - No runnable tests"
        skipped=$((skipped+1))
        echo ""
        continue
    fi

    # Capture the run output so we can both stream it to the user (via tee)
    # and parse the ctest summary line afterwards. The exit code of the
    # subshell is written to a temp file via a trap; relying on the pipe's
    # exit status would only give us tee's status.
    out_file=$(mktemp)
    exit_file=$(mktemp)

    (
        trap 'echo $? > "'"$exit_file"'"' EXIT
        cd "$tests_dir"
        if [ "$clean" -eq 1 ]; then
            printf '%s- Cleaning build artifacts%s\n' "$_c_green" "$_c_reset"
            rm -rf build
            printf '%s- Building project%s\n' "$_c_green" "$_c_reset"
            ./1_build.sh
        fi
        printf '%s- Running tests%s\n' "$_c_green" "$_c_reset"
        ./2_run.sh
    ) 2>&1 | tee "$out_file"

    sub_exit=$(cat "$exit_file" 2>/dev/null || echo 1)
    [ -z "$sub_exit" ] && sub_exit=1
    rm -f "$exit_file"

    if [ "$sub_exit" -ne 0 ]; then
        msg_error "  Test execution failed"
        failed=$((failed+1))
        failed_list="$failed_list\n- $repo_name"
        rm -f "$out_file"
        echo ""
        continue
    fi

    # Sum every "out of N" appearing in the captured output. Each ctest
    # invocation emits exactly one such line; libraries with multiple
    # ctest passes (rare, but supported) contribute multiple matches.
    sublib_count=0
    for n in $(grep -oE "out of [0-9]+" "$out_file" | awk '{print $NF}'); do
        sublib_count=$((sublib_count + n))
    done
    total_tests=$((total_tests + sublib_count))
    rm -f "$out_file"

    msg_ok "  Tests executed ($sublib_count tests)"
    executed=$((executed+1))
    echo ""
done

msg_section "Summary"
printf '  Executed:        %s%d%s\n' "$_c_green" "$executed"    "$_c_reset"
printf '  Total tests run: %s%d%s\n' "$_c_cyan"  "$total_tests" "$_c_reset"
printf '  Skipped:         %s%d%s\n' "$_c_gray"  "$skipped"     "$_c_reset"
printf '  Failed:          %s%d%s\n' "$_c_red"   "$failed"      "$_c_reset"

if [ "$failed" -gt 0 ]; then
    echo ""
    msg_error "Failed tests:"
    printf '%s%b%s\n' "$_c_red" "$failed_list" "$_c_reset"
fi

echo ""
msg_ok "Done!"
