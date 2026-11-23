#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/board_controls.vhd" "$project_dir/tests/tb_board_controls.vhd"
for filter_cycles in 1 4; do
    "$simulator" --elab-run --std=08 tb_board_controls -gfilter_cycles="$filter_cycles" --assert-level=error
done
