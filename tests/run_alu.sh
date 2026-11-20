#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/alu.vhd" "$project_dir/tests/tb_alu.vhd"
"$simulator" -e --std=08 tb_alu
"$simulator" -r --std=08 tb_alu --assert-level=error
