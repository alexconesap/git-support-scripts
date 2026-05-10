#!/usr/bin/env bash
# Formats C/C++ source files using clang-format.
# Arguments can be individual files or directories. When a directory is provided, it will be processed recursively.
# With no arguments, lists every sibling folder that has its own .clang-format file and asks whether to format them all.
# Usage:
#   ./format_c_files.sh                                      # discover + confirm + format every lib with a .clang-format
#   ./format_c_files.sh <dir_or_file> [more paths...]        # format the given paths only
#   ./support/format_c_files.sh src/ include/ tests/test_file.cpp

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

if ! command -v clang-format >/dev/null 2>&1; then
    msg_error "clang-format is not installed."
    exit 1
fi

# No arguments: discover sibling folders that contain a .clang-format file,
# show them, and ask for confirmation before formatting all of them.
if (($# == 0)); then
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    root_dir=${script_dir%/support}

    candidates=()
    while IFS= read -r dir; do
        candidates+=("$dir")
    done < <(
        find "$root_dir" -mindepth 2 -maxdepth 2 -type f -name '.clang-format' \
            -not -path '*/tests/vendor/*' \
            -not -path '*/libraries/*' -print |
            sed "s|/\.clang-format$||" |
            sed "s|^$root_dir/||" |
            sort
    )

    if ((${#candidates[@]} == 0)); then
        msg_error "No directories with a .clang-format file were found under $root_dir."
        exit 1
    fi

    msg_section "Directories with a .clang-format file"
    for dir in "${candidates[@]}"; do
        msg_bullet "$dir"
    done
    echo ""

    msg_prompt "Do you want to process all of them? [y/N]"
    read -r answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) msg_warn "Aborted."; exit 0 ;;
    esac

    set -- "${candidates[@]/#/$root_dir/}"
fi

is_cpp_file() {
    case "$1" in
        *.ino|*.c|*.cpp|*.h|*.hpp) return 0 ;;
        *) return 1 ;;
    esac
}

format_file() {
    local file="$1"
    clang-format -i -style=file "$file"
    msg_ok "Formatted: $file"
}

for path in "$@"; do
    if [[ -d "$path" ]]; then
        msg_section "Processing directory: $path"
        while IFS= read -r -d '' file; do
            format_file "$file"
        done < <(
            find "$path" \
                \( \
                    -type l -o \
                    -type d -name 'libraries' -o \
                    -type d -path '*/tests/vendor' -o \
                    -type d -path '*/tests/build' \
                \) -prune -o \
                -type f \( \
                    -name '*.c' -o -name '*.cpp' -o \
                    -name '*.h' -o -name '*.hpp' -o \
                    -name '*.ino' \
                \) -print0
        )

    elif [[ -f "$path" ]]; then
        if is_cpp_file "$path"; then
            msg_info "Processing file: $path"
            format_file "$path"
        else
            msg_warn "Unsupported file type: $path"
        fi

    else
        msg_warn "Path does not exist: $path"
    fi
done

echo ""
msg_ok "Formatting complete."