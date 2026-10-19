#!/usr/bin/env bash
# Publishes a version tag as a public GitHub release (DEC-0028 §2 and §3; DEC-0033): both builds,
# with docs/releases/TAG.md, in Portuguese, as the notes. The CI's release job runs it on a pushed
# tag v0.y.z, with the export job's builds in build/:
#   bash tools/release.sh TAG
#   bash tools/release.sh --dry-run [TAG]      (v plus the version of project.godot by default)
# It refuses unless TAG is v plus application/config/version, both builds are whole (check_build)
# and the notes exist. The dry run makes every check and prints the command instead of running
# it; there a missing notes file is only reported, since the first notes, for v0.1.0, come with
# TASK-9, criterion #18. The CI rehearses it on every PR.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/build_lib.sh

usage() {
	echo "usage: bash tools/release.sh TAG, or bash tools/release.sh --dry-run [TAG]" >&2
	exit 2
}

dry_run=false
if [ "${1:-}" = --dry-run ]; then
	dry_run=true
	shift
fi
version="$(project_version)"
if [ "$#" -gt 1 ] || { ! $dry_run && [ "$#" -ne 1 ]; }; then
	usage
fi
tag="${1:-v$version}"
notes="docs/releases/$tag.md"

refusals=0
refuse() {
	echo "refused: $1" >&2
	refusals=$((refusals + 1))
}

if [ -z "$version" ]; then
	refuse "project.godot has no application/config/version"
elif [ "$tag" != "v$version" ]; then
	refuse "the tag is $tag, but project.godot has the version $version: the tag must be v$version (DEC-0028 §3)"
fi
for build in "$client_build" "$server_build"; do
	if reason="$(check_build "$build" 2>&1)"; then
		echo "build: $build is whole, $(wc -c <"$build" | tr -d '[:space:]') bytes"
	else
		refuse "$reason"
	fi
done
if [ -f "$notes" ]; then
	echo "notes: $notes"
elif $dry_run; then
	echo "notes: $notes does not exist yet; a real release refuses without it, and the first" \
		"notes, for v0.1.0, come with TASK-9, criterion #18"
else
	refuse "$notes is missing: the release notes, in Portuguese, from the devlog (DEC-0028 §3)"
fi
if ! command -v gh >/dev/null 2>&1; then
	refuse "gh, the GitHub CLI, is not installed"
fi
if [ "$refusals" -gt 0 ]; then
	echo "release $tag refused" >&2
	exit 1
fi

# --verify-tag: the tag must already be on GitHub, so gh never creates one by itself.
release=(gh release create "$tag" "$client_build" "$server_build" --title "$tag"
	--notes-file "$notes" --verify-tag)
if $dry_run; then
	echo "dry run of the release $tag passed; the release would run:"
	printf '%q ' "${release[@]}"
	echo
	exit 0
fi
"${release[@]}"
echo "released $tag"
