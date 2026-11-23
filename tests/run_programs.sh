#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cp -- "$project_dir"/p1_arith.mif "$project_dir"/p2_limit.mif \
      "$project_dir"/p3_mem.mif "$project_dir"/p4_r0_jump.mif "$build_dir/"
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
    "$project_dir/tests/tb_program.vhd"

for program in 1 2 3 4; do
    wave_args=()
    if [[ -n "${VCD_DIR:-}" ]]; then
        mkdir -p -- "$VCD_DIR"
        wave_args=(--vcd="$VCD_DIR/wave_p${program}.vcd")
    fi
    "$simulator" --elab-run --std=08 tb_program -gprogram="$program" \
        --assert-level=error "${wave_args[@]}"
done
