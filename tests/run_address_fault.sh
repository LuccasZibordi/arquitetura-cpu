#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
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
    "$project_dir/tests/tb_address_fault.vhd"
for scenario in {1..8}; do
    case "$scenario" in
        1) words=(623F A001); boundary=FACE ;; # LD R1,-1(R0)
        2) words=(5205 723F A002); boundary=FACE ;; # ST R1,-1(R0)
        3) words=(6210 6440 A002); boundary=FACE ;; # base=0400, LD R2,0(R1)
        4) words=(6210 7440 A002); boundary=FACE ;; # base=0400, ST R2,0(R1)
        5) words=(5201 A400); boundary=FACE ;; # JMP 0400
        6) words=(803E); boundary=FACE ;; # BEQ R0,R0,-2 -> FFFF
        7) words=(A3FF); boundary=0000 ;; # instrucao em 03FF, proxima busca 0400
        8) words=(6210 6440 7440 A3FF); boundary=A3FF ;; # LD/ST/JMP em 03FF
    esac
    {
        cat <<'MIF'
DEPTH = 1024;
WIDTH = 16;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT BEGIN
[000..3FF] : 0000;
MIF
        for index in "${!words[@]}"; do
            printf '%03X : %s;\n' "$index" "${words[$index]}"
        done
        if [[ "$scenario" == 8 ]]; then
            printf '010 : 03FF;\n'
        else
            printf '010 : 0400;\n'
        fi
        printf '3FF : %s;\nEND;\n' "$boundary"
    } > address_test.mif
    "$simulator" --elab-run --std=08 tb_address_fault -gscenario="$scenario" --assert-level=error
done
