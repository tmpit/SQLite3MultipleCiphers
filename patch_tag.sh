#!/bin/sh

set -e # Fail immediately if a command returns a non-zero code.
set -o pipefail

# This script creates a tag from the specified tag from the upstream repo and applies the ios.patch to it.

script_name=$(basename "$0")
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

PATCH_FILE="ios.patch"

function print_help {
	cat << EOF
OVERVIEW: Create a tag from an upstream tag by applying the ios.patch to it.

USAGE: $script_name <tag> <version>

PARAMETERS:
    <tag> The upstream git tag from which to create our tag.
    <version> A version number to append to our tag.
EOF
}

function fail_usage {
	echo $1
	echo
	print_help
	exit 1
}

function fail {
	echo $1
	exit 1
}

tag=$1
version=$2

[[ -z "$tag" ]] && fail_usage "Please provide an upstream tag."
[[ -z "$version" ]] && fail_usage "Please provide a version number."

if ! git rev-parse "$tag" >/dev/null 2>&1; then
	fail "The tag \"$tag\" is not recognized by the git repository."
fi

new_tag="${tag}_ios/${version}"

if git tag | grep "$new_tag" >/dev/null; then
	fail "A tag named \"$new_tag\" already exists."
fi

patch=$(cat "$PATCH_FILE")

echo "Checking out to tag $tag"
git checkout "$tag"

echo "Applying patch"
echo "$patch" > "$PATCH_FILE"
git apply "$PATCH_FILE"
rm "$PATCH_FILE"

echo "Committing changes"
git add .
git commit -m "Apply $PATCH_FILE"

echo "Creating tag $new_tag"
git tag -a "$new_tag" -m "$tag patched"

echo "Pushing to origin"
git push --tags

echo
echo "Done! $tag is patched in:"
echo "$new_tag"


