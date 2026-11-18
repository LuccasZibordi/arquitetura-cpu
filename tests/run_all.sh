#!/usr/bin/env bash
set -euo pipefail
tests_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for test_name in register_file instruction_register pc immediate_extender instruction_formats; do
    bash "$tests_dir/run_${test_name}.sh"
done
