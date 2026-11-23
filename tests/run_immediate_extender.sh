#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/immediate_extender.vhd" "$project_dir/tests/tb_immediate_extender.vhd"
"$simulator" -e --std=08 tb_immediate_extender
"$simulator" -r --std=08 tb_immediate_extender --assert-level=error
