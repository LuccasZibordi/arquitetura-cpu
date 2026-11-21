#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cp -- "$project_dir/memory_test.mif" "$build_dir/"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/memory.vhd" \
    "$project_dir/memory_address_register.vhd" "$project_dir/memory_data_register.vhd" \
    "$project_dir/tests/tb_memory.vhd"
"$simulator" -e --std=08 tb_memory
"$simulator" -r --std=08 tb_memory --assert-level=error
