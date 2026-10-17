#!/usr/bin/env bash
# The deterministic gate (DEC-0027): what pre-push and CI run. Any failure stops it.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"
started=$SECONDS

step() { printf '\n== %s\n' "$1"; }

step "Format and lint"
bash tools/check_format.sh

step "Core purity (DEC-0004 rule 1)"
bash tools/check_core_purity.sh

step "Assets and LFS (DEC-0029)"
bash tools/check_assets.sh

step "Locked acceptance tests (DEC-0009)"
bash tools/check_test_locks.sh

step "Import"
if ! import_log="$("$godot_bin" --headless --path . --import 2>&1)"; then
	echo "$import_log"
	echo "import failed"
	exit 1
fi
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" <<<"$import_log"; then
	echo "import reported errors"
	exit 1
fi
echo "import ok"

step "Compile every script (DEC-0005; DEC-0022)"
bash tools/check_scripts.sh

step "Tests (gdUnit4)"
bash tools/run_tests.sh

printf '\ngate green in %ss\n' "$((SECONDS - started))"
