#!/usr/bin/env bash
# Stamps the commit a build is made from into project.godot, as application/config/commit, right
# after config/version (DEC-0028 §3; F-045 §3). The CI runs it just before exporting, and the
# handshake compares the stamp (rede.md §9). An earlier stamp is replaced:
#   bash tools/stamp_build.sh COMMIT      (7 to 40 lowercase hex digits; the CI gives the first 7)
# The editor and the gate run without a stamp, so a stamped project.godot is never committed: the
# gate's settings test refuses it. tools/server_image_check.sh restores the file by itself.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/build_lib.sh

commit="${1:-}"
if [ "$#" -ne 1 ] || ! [[ "$commit" =~ ^[0-9a-f]{7,40}$ ]]; then
	echo "usage: bash tools/stamp_build.sh COMMIT, 7 to 40 lowercase hex digits, like 4dfb475" >&2
	exit 2
fi

stamped="$(mktemp)"
trap 'rm -f "$stamped"' EXIT
if ! awk -v commit="$commit" '
	/^\[/ { in_application = ($0 ~ /^\[application\][ \t\r]*$/) }
	in_application && /^config\/commit=/ { next }
	{ print }
	in_application && !done && /^config\/version=/ {
		print "config/commit=\"" commit "\""
		done = 1
	}
	END { exit done ? 0 : 1 }
' project.godot >"$stamped"; then
	echo "project.godot has no config/version under [application]: the stamp goes after it" >&2
	exit 1
fi
cat "$stamped" >project.godot

if [ "$(project_commit)" != "$commit" ]; then
	echo "project.godot does not read back the commit $commit after stamping" >&2
	exit 1
fi
echo "stamped application/config/commit=\"$commit\" in project.godot; never commit it"
