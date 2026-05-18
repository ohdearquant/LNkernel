.PHONY: check clippy test fmt fmt-check build clean ci docs-check lean-build lean-ci lean-clean

# ── Rust workspace (crates/) ────────────────────────────────────────────

check:
	cd crates && cargo check --workspace

clippy:
	cd crates && cargo clippy --workspace --all-targets -- -D warnings

test:
	cd crates && cargo test --workspace

fmt:
	cd crates && cargo fmt --all
	deno fmt

fmt-check:
	cd crates && cargo fmt --all -- --check
	deno fmt --check

build:
	cd crates && cargo build --workspace --release

clean:
	cd crates && cargo clean

# ── Lean proofs (proofs/) ───────────────────────────────────────────────

lean-build:
	cd proofs && lake build

lean-ci:
	bash scripts/lean_ci.sh

lean-clean:
	cd proofs && rm -rf .lake build

# ── Aggregate ──────────────────────────────────────────────────────────

ci:
	bash scripts/ci.sh
	bash scripts/lean_ci.sh
	deno fmt --check

docs-check:
	deno fmt --check
