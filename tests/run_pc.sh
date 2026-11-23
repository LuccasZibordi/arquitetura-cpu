#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
simulator="${GHDL:-ghdl}"
cd "$build_dir"
"$simulator" -a --std=08 "$project_dir/pc.vhd" "$project_dir/tests/tb_pc.vhd"
"$simulator" -e --std=08 tb_pc
"$simulator" -r --std=08 tb_pc --assert-level=error
