#!/usr/bin/env bash
# Formats C/C++ source files using clang-format.
# Arguments can be individual files or directories. When a directory is provided, it will be processed recursively.
# Usage:
#   ./format_c_files.sh <dir_or_file> [more paths...]
#   ./support/format_c_files.sh src/ include/ tests/test_file.cpp

set -euo pipefail

if (($# == 0)); then
    echo "Usage: $0 <dir_or_file> [more paths...]" >&2
    exit 1
fi

if ! command -v clang-format >/dev/null 2>&1; then
    echo "Error: clang-format is not installed." >&2
    exit 1
fi

is_cpp_file() {
    case "$1" in
        *.c|*.cpp|*.h|*.hpp) return 0 ;;
        *) return 1 ;;
    esac
}

format_file() {
    local file="$1"
    clang-format -i -style=file "$file"
    printf '✔ Formatted: %s\n' "$file"
}

for path in "$@"; do
    if [[ -d "$path" ]]; then
        printf 'Processing directory: %s\n' "$path"
        while IFS= read -r -d '' file; do
            format_file "$file"
        done < <(
            find "$path" \
                \( \
                    -type d -path '*/tests/vendor' -o \
                    -type d -path '*/tests/build' \
                \) -prune -o \
                -type f \( \
                    -name '*.c' -o -name '*.cpp' -o \
                    -name '*.h' -o -name '*.hpp' \
                \) -print0
        )

    elif [[ -f "$path" ]]; then
        if is_cpp_file "$path"; then
            printf 'Processing file: %s\n' "$path"
            format_file "$path"
        else
            printf 'Warning: unsupported file type: %s\n' "$path" >&2
        fi

    else
        printf 'Warning: path does not exist: %s\n' "$path" >&2
    fi
done

echo "Formatting complete."