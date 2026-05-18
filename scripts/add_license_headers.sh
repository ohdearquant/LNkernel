#!/usr/bin/env bash
# Add per-file license headers to .lean (Apache-2.0) and .rs (AGPL-3.0) files.
#
# Idempotent: skips files that already carry a SPDX or "Released under" marker.
# Run from anywhere; resolves paths relative to the repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LEAN_HEADER='/-
Copyright (c) 2026 HaiyangLi. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: HaiyangLi
-/
'

RUST_HEADER='// Copyright (C) 2026 HaiyangLi
// SPDX-License-Identifier: AGPL-3.0-or-later
'

lean_count=0
lean_skipped=0
while IFS= read -r -d '' file; do
    if grep -qE '(SPDX-License-Identifier|Released under Apache)' "$file" 2>/dev/null; then
        lean_skipped=$((lean_skipped + 1))
        continue
    fi
    tmp="$(mktemp)"
    printf '%s' "$LEAN_HEADER" > "$tmp"
    cat "$file" >> "$tmp"
    mv "$tmp" "$file"
    lean_count=$((lean_count + 1))
done < <(find proofs -name '*.lean' -print0)

rust_count=0
rust_skipped=0
while IFS= read -r -d '' file; do
    if grep -q 'SPDX-License-Identifier' "$file" 2>/dev/null; then
        rust_skipped=$((rust_skipped + 1))
        continue
    fi
    tmp="$(mktemp)"
    printf '%s' "$RUST_HEADER" > "$tmp"
    cat "$file" >> "$tmp"
    mv "$tmp" "$file"
    rust_count=$((rust_count + 1))
done < <(find crates -name '*.rs' -not -path '*/target/*' -print0)

echo "Lean files: $lean_count updated, $lean_skipped skipped (already headed)"
echo "Rust files: $rust_count updated, $rust_skipped skipped (already headed)"
