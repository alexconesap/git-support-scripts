#!/bin/sh
# This script runs tests for all repositories found in the current directory that contains a 'tests' directory.

set -eu

RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "Running tests"
echo ""

current_dir=$(pwd)

case "$current_dir" in
    */support) updates_dir=${current_dir%/support} ;;
    *) updates_dir=$current_dir ;;
esac

executed=0
skipped=0
failed=0
failed_list=""

for repo_path in "$updates_dir"/*; do
    [ -d "$repo_path" ] || continue
    [ -L "$repo_path" ] && continue

    repo_name=$(basename "$repo_path")
    tests_dir="$repo_path/tests"
    run_script="$tests_dir/2_run.sh"

    printf "• %s\n" "$repo_name"

    if [ ! -d "$tests_dir" ] || [ ! -f "$run_script" ]; then
        echo "  - No runnable tests"
        skipped=$((skipped+1))
        echo ""
        continue
    fi

    (
        cd "$tests_dir"
        ./2_run.sh
    ) || {
        echo "  ✖ Test execution failed"
        failed=$((failed+1))
        failed_list="$failed_list\n- $repo_name"
        echo ""
        continue
    }

    echo "  ✔ Tests executed"
    executed=$((executed+1))
    echo ""
done

echo "Summary:"
echo "  Executed: $executed"
echo "  Skipped: $skipped"
echo "  Failed: $failed"

if [ "$failed" -gt 0 ]; then
    echo ""
    printf "${RED}Failed tests:${NC}\n"
    printf "${RED}%b${NC}\n" "$failed_list"
fi

echo ""
echo "Done!"