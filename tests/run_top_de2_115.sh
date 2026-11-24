#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cp -- "$project_dir/cpu_test.mif" "$build_dir/"
cp -- "$project_dir/tests/top_memory.mif" "$build_dir/"
cat > "$build_dir/top_fault.mif" <<'MIF'
DEPTH = 1024;
WIDTH = 16;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT BEGIN
000 : A400;
[001..3FF] : 0000;
END;
MIF
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
    "$project_dir/board_controls.vhd" \
    "$project_dir/top_de2_115.vhd" \
    "$project_dir/tests/tb_top_de2_115.vhd"
{
    printf 'DEPTH = 1024;\nWIDTH = 16;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT BEGIN\n'
    for ((digit=0; digit<16; digit++)); do printf '%03X : F%X%X%X;\n' "$digit" "$digit" "$digit" "$digit"; done
    printf '[010..3FF] : 0000;\nEND;\n'
} > top_digits.mif
"$simulator" --elab-run --std=08 tb_top_de2_115 -gdigits_case=true --assert-level=error
"$simulator" --elab-run --std=08 tb_top_de2_115 -gmemory_case=true --assert-level=error
for fault_case in false true; do
    "$simulator" --elab-run --std=08 tb_top_de2_115 -gfault_case="$fault_case" --assert-level=error
done
