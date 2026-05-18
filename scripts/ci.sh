#!/bin/sh
# CI script for the Rust side of LNkernel.
# Run from anywhere; resolves the crates workspace relative to repo root.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../crates"

echo "=== Format Check ==="
cargo fmt --all -- --check

echo "=== Clippy ==="
cargo clippy --workspace --all-targets -- -D warnings

echo "=== Tests ==="
cargo test --workspace

echo "=== No-Default-Features Check ==="
cargo check --workspace --no-default-features

echo "=== Doc Build ==="
RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps

echo "=== Build (release) ==="
cargo build --workspace --release

echo "=== Rust CI Passed ==="
