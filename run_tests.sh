#!/bin/sh
# This script runs tests for all repositories found in the current directory that contains a 'tests' directory.
# Usage:
#   ./run_tests.sh [--clean] [folder ...]
# Options:
#   --clean: Remove existing build artifacts before running tests.
#   folder:  Optional list of library folder names to limit execution. If omitted, all repositories are tested.

set -eu

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'

print_line() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

clean=0
filter=""
for arg in "$@"; do
    case "$arg" in
        --clean) clean=1 ;;
        -*) echo "Unknown argument: $arg" >&2; exit 1 ;;
        *) filter="$filter $arg" ;;
    esac
done

echo ""
echo "Running tests"
[ "$clean" -eq 1 ] && echo "Clean build enabled"
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

    print_line
    printf "• %s\n" "$repo_name"
    print_line

    if [ ! -d "$tests_dir" ] || [ ! -f "$run_script" ]; then
        echo " - No runnable tests" skipped=$((skipped+1))
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
            echo "${GREEN}- Cleaning build artifacts${NC}"
            rm -rf build
            echo "${GREEN}- Building project${NC}"
            ./1_build.sh
        fi
        echo "${GREEN}- Running tests${NC}"
        ./2_run.sh
    ) 2>&1 | tee "$out_file"

    sub_exit=$(cat "$exit_file" 2>/dev/null || echo 1)
    [ -z "$sub_exit" ] && sub_exit=1
    rm -f "$exit_file"

    if [ "$sub_exit" -ne 0 ]; then
        echo "  ✖ Test execution failed"
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

    echo "  ✔ Tests executed ($sublib_count tests)"
    executed=$((executed+1))
    echo ""
done

echo "Summary:"
echo "  Executed: $executed"
echo "  Total tests run: $total_tests"
echo "  Skipped: $skipped"
echo "  Failed: $failed"

if [ "$failed" -gt 0 ]; then
    echo ""
    printf "${RED}Failed tests:${NC}\n"
    printf "${RED}%b${NC}\n" "$failed_list"
fi

echo ""
echo "Done!"
