#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cp -- "$project_dir"/*.mif "$build_dir/"
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
    "$project_dir/decoder.vhd" \
    "$project_dir/control_unit.vhd" \
    "$project_dir/cpu.vhd" \
    "$project_dir/tests/tb_cpu_enable.vhd"
cat > address_1.mif <<'MIF'
DEPTH = 1024;
WIDTH = 16;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT BEGIN
000 : 623F;
001 : A001;
[002..3FF] : 0000;
END;
MIF
for init_file in cpu_test.mif p1_arith.mif p2_limit.mif p3_mem.mif p4_r0_jump.mif address_1.mif; do
    expect_fault=false
    [[ "$init_file" != address_1.mif ]] || expect_fault=true
    "$simulator" --elab-run --std=08 tb_cpu_enable -ginit_file="$init_file" \
        -gexpect_fault="$expect_fault" --assert-level=error
done
