#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/instruction_register.vhd" "$project_dir/immediate_extender.vhd" "$project_dir/tests/tb_instruction_formats.vhd"
"$simulator" -e --std=08 tb_instruction_formats
"$simulator" -r --std=08 tb_instruction_formats --assert-level=error
