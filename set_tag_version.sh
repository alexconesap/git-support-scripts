#!/bin/sh

# Bump a library to a new version and publish it.
#
# Usage: support/set_tag_version.sh <library-folder> <version>
#   <library-folder>  folder name under the repo root (e.g. lib_motor)
#   <version>         semver without the leading v (e.g. 1.0.2 or 2.1.0)
#
# Actions:
#   1. Updates library.properties `version=` line
#   2. Writes <version> into .version
#   3. git add + commit with the host's configured git user
#   4. Creates annotated tag v<version>
#   5. Pushes the current branch and the new tag
#
# Commits and tags use the git user configured on the machine — this script
# does NOT override user.name / user.email.

set -eu

. "$(dirname -- "$0")/common.sh"

usage() {
    msg_error "Usage: $0 <library-folder> <version>"
    msg_dim   "  e.g. $0 lib_motor 2.0.3" >&2
    exit 2
}

[ $# -eq 2 ] || usage

lib=$1
version=$2

# Strip trailing slash a user may have tab-completed
lib=${lib%/}

# Validate semver (M.m.p, digits only)
case "$version" in
    [0-9]*.[0-9]*.[0-9]*)
        if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
            msg_error "Version '$version' is not a valid semver (M.m.p)"
            exit 2
        fi
        ;;
    *)
        msg_error "Version '$version' is not a valid semver (M.m.p)"
        exit 2
        ;;
esac

tag="v$version"

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
root_dir=${script_dir%/support}
repo_path="$root_dir/$lib"

[ -d "$repo_path" ] || {
    msg_error "Library folder not found: $repo_path"
    exit 1
}
[ -e "$repo_path/.git" ] || {
    msg_error "Not a git repository: $repo_path"
    exit 1
}

props="$repo_path/library.properties"
[ -f "$props" ] || {
    msg_error "library.properties not found in $repo_path"
    exit 1
}

# Refuse if the tag already exists locally or on origin
if git -C "$repo_path" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    msg_error "Tag $tag already exists in local repo"
    exit 1
fi
if git -C "$repo_path" ls-remote --tags origin "$tag" | grep -q "refs/tags/$tag"; then
    msg_error "Tag $tag already exists on origin"
    exit 1
fi

# Sanity: no unrelated pending changes
if [ -n "$(git -C "$repo_path" status --porcelain -- . ':!library.properties' ':!.version')" ]; then
    msg_error "$lib has uncommitted changes outside library.properties/.version"
    msg_dim  "Commit or stash them first."
    git -C "$repo_path" status --short >&2
    exit 1
fi

msg_section "Bumping $lib to $version"

# library.properties: replace the version= line in-place (portable sed)
tmp=$(mktemp)
awk -v v="$version" '
    BEGIN { done = 0 }
    /^version=/ && !done { print "version=" v; done = 1; next }
    { print }
    END { if (!done) { print "version=" v } }
' "$props" > "$tmp" && mv "$tmp" "$props"

# .version file (required by CLAUDE.md convention)
printf '%s\n' "$version" > "$repo_path/.version"

cd "$repo_path"

git add library.properties .version

if git diff --cached --quiet; then
    msg_info "library.properties and .version already at $version — no commit needed."
else
    git commit -m "chore: bump version to $version"
fi

git tag -a "$tag" -m "Release $version"

branch=$(git symbolic-ref --quiet --short HEAD || echo "")
if [ -z "$branch" ]; then
    msg_error "Detached HEAD — aborting push"
    exit 1
fi

msg_info "Pushing $branch and $tag to origin ..."
git push origin "$branch"
git push origin "$tag"

echo ""
msg_ok "Done: $lib is now at $version (tag $tag)."
