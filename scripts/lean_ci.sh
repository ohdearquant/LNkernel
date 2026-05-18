#!/bin/sh
# CI script for the Lean side of LNkernel.
# Builds the Lion library and checks for stray `sorry`s.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../proofs"

echo "=== Lake Manifest ==="
lake --version

echo "=== Build Lion library ==="
lake build

echo "=== Sorry / Admit Check ==="
# Fail if any non-test .lean file under proofs/ contains `sorry` or `admit`
# at the start of a line or after whitespace. We allow these tokens inside
# comments by skipping lines starting with `--` after trimming.
hits="$(grep -RnE '^[[:space:]]*(sorry|admit)\b' --include='*.lean' Lion Lion.lean 2>/dev/null || true)"
if [ -n "$hits" ]; then
    echo "Found bare sorry/admit:"
    echo "$hits"
    exit 1
fi

echo "=== Lean CI Passed ==="
