#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cp -- "$project_dir/datapath_test.mif" "$build_dir/"
cd "$build_dir"
"$simulator" -a --std=08 \
    "$project_dir/pc.vhd" \
    "$project_dir/instruction_register.vhd" \
    "$project_dir/memory.vhd" \
    "$project_dir/register_file.vhd" \
    "$project_dir/immediate_extender.vhd" \
    "$project_dir/reg_a.vhd" \
    "$project_dir/reg_b.vhd" \
    "$project_dir/alu.vhd" \
    "$project_dir/alu_out.vhd" \
    "$project_dir/memory_address_register.vhd" \
    "$project_dir/memory_data_register.vhd" \
    "$project_dir/datapath.vhd" \
    "$project_dir/tests/tb_datapath.vhd"
"$simulator" -e --std=08 tb_datapath
"$simulator" -r --std=08 tb_datapath --assert-level=error
