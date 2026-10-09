#!/usr/bin/env bash
# DEC-0029: a third-party asset enters only as a pack in assets/third_party/<fonte>/<pack>/, in
# snake_case, with its licence file inside the pack and one row in assets/CREDITS.md citing the
# pack's path. "Asset sem linha não entra" is this gate step (TASK-7, criterion 3). The same step
# proves through git itself that .gitattributes sends every format the policy accepts to Git LFS
# and leaves the text formats out (TASK-7, criterion 7).
# The canaries in tools/canaries/assets/ run on every call through the same check_root: each
# bad_* root must be flagged and each good_* root must pass, or this check has lost a rule
# (DEC-0027). Plain find, grep and sed: CI runs ubuntu-24.04, the PC runs Git Bash.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob
export LC_ALL=C

# The formats that go to Git LFS (DEC-0029; DEC-0027). docs/design/visual-e-audio.md lists the
# same formats, with the reason for every format left out.
lfs_formats=(
	png jpg jpeg webp exr hdr psd kra tga dds ktx2
	glb gltf bin obj dae fbx blend
	wav ogg mp3 flac
	ttf otf woff woff2
	mp4 webm
)
# Text formats that must stay out of LFS: git diffs them and Godot reads them as text.
text_probes=(
	main.tscn
	project.godot
	assets/third_party/sonda/pack/x.import
	assets/third_party/sonda/pack/icone.svg
	assets/third_party/sonda/pack/modelo.txt
	assets/third_party/sonda/pack/dados.tres
)

# Prints the packs of one assets/third_party/: the folders at depth 2 that hold at least one file.
list_packs() {
	local dir
	while IFS= read -r dir; do
		if [ -n "$(find "$dir" -type f)" ]; then
			echo "$dir"
		fi
	done < <(find "$1" -mindepth 2 -maxdepth 2 -type d | sort)
}

# Checks one project root ("." or a canary): prints "path: reason" for every failure and returns 1
# when there is any. Leaves the number of packs in packs_found for the summary line.
check_root() {
	local root=${1%/}
	local prefix=""
	if [ "$root" != "." ]; then
		prefix="$root/"
	fi
	local third="${prefix}assets/third_party"
	local credits="${prefix}assets/CREDITS.md"
	local failures=0 path name pack relative licences
	packs_found=0
	if [ ! -d "$third" ]; then
		return 0
	fi
	if [ ! -f "$credits" ]; then
		echo "$credits: missing; every pack needs its row there (DEC-0029)"
		failures=$((failures + 1))
	fi
	# A file at depth 0 or 1 sits outside any pack.
	while IFS= read -r path; do
		echo "$path: a file outside a pack; assets live in assets/third_party/<fonte>/<pack>/ (DEC-0029)"
		failures=$((failures + 1))
	done < <(find "$third" -mindepth 1 -maxdepth 2 -type f | sort)
	# <fonte> and <pack> folder names are snake_case.
	while IFS= read -r path; do
		name=${path##*/}
		case "$name" in
		"" | *[!a-z0-9_]*)
			echo "$path: folder name must be snake_case, [a-z0-9_] only (DEC-0029)"
			failures=$((failures + 1))
			;;
		esac
	done < <(find "$third" -mindepth 1 -maxdepth 2 -type d | sort)
	# Every pack carries its licence file, under its original name, and its row in CREDITS.md.
	# The row must cite the canonical path assets/third_party/<fonte>/<pack> with no trailing
	# slash; -w stops the row of pack_v2 from passing as the row of pack.
	while IFS= read -r pack; do
		packs_found=$((packs_found + 1))
		licences="$(find "$pack" -maxdepth 1 -type f \
			\( -iname 'licen[cs]e*' -o -iname 'ofl*' -o -iname 'copying*' \))"
		if [ -z "$licences" ]; then
			echo "$pack: no licence file (LICENSE*, LICENCE*, OFL* or COPYING*) inside the pack (DEC-0029)"
			failures=$((failures + 1))
		fi
		relative=${pack#"$prefix"}
		if ! grep -F -w -q -- "$relative" "$credits" 2>/dev/null; then
			echo "$pack: no row in assets/CREDITS.md citing $relative (DEC-0029)"
			failures=$((failures + 1))
		fi
	done < <(list_packs "$third")
	[ "$failures" -eq 0 ]
}

status=0

if ! check_root .; then
	echo "assets/third_party/ must follow DEC-0029: a pack needs its licence file and its row in assets/CREDITS.md, a snake_case name, and no file outside a pack."
	status=1
fi
real_packs=$packs_found

canary_dir=tools/canaries/assets
bad=("$canary_dir"/bad_*/)
good=("$canary_dir"/good_*/)
if [ "${#bad[@]}" -eq 0 ] || [ "${#good[@]}" -eq 0 ]; then
	echo "no bad_*/ or good_*/ in $canary_dir: the assets check lost its self-test (TASK-7)"
	exit 1
fi
for canary in "${bad[@]}"; do
	if check_root "$canary" >/dev/null; then
		echo "canary $canary: expected flagged, got clean: the assets check lost a rule (TASK-7)"
		status=1
	fi
done
for canary in "${good[@]}"; do
	if ! hits="$(check_root "$canary")"; then
		echo "canary $canary: expected clean, got flagged: the assets check lost a rule (TASK-7)"
		echo "$hits" | sed 's/^/  /'
		status=1
	fi
done

# git itself answers which filter a path would get: "lfs" for every accepted format, and
# "unspecified" for the text formats. The probe paths need not exist.
lfs_probes=()
for ext in "${lfs_formats[@]}"; do
	lfs_probes+=("assets/third_party/sonda/pack/modelo.$ext")
done
tracked=0
answered=0
while IFS= read -r line; do
	answered=$((answered + 1))
	case "$line" in
	*": filter: lfs")
		tracked=$((tracked + 1))
		;;
	*)
		echo "${line%%: filter: *}: filter is ${line##*: filter: }; .gitattributes must send this format to Git LFS (DEC-0029)"
		status=1
		;;
	esac
done < <(git check-attr filter -- "${lfs_probes[@]}")
if [ "$answered" -ne "${#lfs_probes[@]}" ]; then
	echo "git check-attr answered $answered of ${#lfs_probes[@]} LFS probes: run this check inside the repository"
	status=1
fi
free=0
answered=0
while IFS= read -r line; do
	answered=$((answered + 1))
	case "$line" in
	*": filter: unspecified")
		free=$((free + 1))
		;;
	*)
		echo "${line%%: filter: *}: filter is ${line##*: filter: }; a text format must stay out of Git LFS (DEC-0029)"
		status=1
		;;
	esac
done < <(git check-attr filter -- "${text_probes[@]}")
if [ "$answered" -ne "${#text_probes[@]}" ]; then
	echo "git check-attr answered $answered of ${#text_probes[@]} text probes: run this check inside the repository"
	status=1
fi

if [ "$status" -ne 0 ]; then
	exit "$status"
fi
echo "lfs ok: $tracked formats tracked, $free text formats free"
canaries="canaries ok: ${#bad[@]} bad flagged, ${#good[@]} good clean"
if [ "$real_packs" -eq 0 ]; then
	echo "assets ok: no packs yet ($canaries)"
elif [ "$real_packs" -eq 1 ]; then
	echo "assets ok: 1 pack ($canaries)"
else
	echo "assets ok: $real_packs packs ($canaries)"
fi
