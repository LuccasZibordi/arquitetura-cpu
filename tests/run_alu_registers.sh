#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/alu.vhd" "$project_dir/reg_a.vhd" "$project_dir/reg_b.vhd" "$project_dir/alu_out.vhd" "$project_dir/tests/tb_alu_registers.vhd"
"$simulator" -e --std=08 tb_alu_registers
"$simulator" -r --std=08 tb_alu_registers --assert-level=error
