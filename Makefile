.PHONY: check clippy test fmt fmt-check build clean ci rust-ci docs-check lean-build lean-ci lean-clean package publish-dry publish

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

# Rust + docs only (skip Lean). Used as the gate for `publish`, since the
# crates.io upload doesn't ship Lean artefacts and gating on a 25-min
# mathlib build would block the release path.
rust-ci:
	bash scripts/ci.sh
	deno fmt --check

docs-check:
	deno fmt --check

# ── Publish (crates.io) ────────────────────────────────────────────────
#
# `package` builds the publishable tarball for inspection (no upload).
# `publish-dry` runs the full crates.io validation pipeline without uploading.
# `publish` performs the real, irreversible upload. crates.io locks each
# published version forever (you can only `yank`, not delete) — every `publish`
# call is a one-way door. Always run `publish-dry` first.

package:
	cd crates/lion-core && cargo package --no-verify
	@echo "Package tarball at: crates/target/package/lion-core-*.crate"

publish-dry:
	cd crates/lion-core && cargo publish --dry-run
	@echo "Dry run OK. To publish for real: make publish"

publish: rust-ci
	@echo "About to publish lion-core to crates.io. This is irreversible."
	@echo "Cargo.toml version:"
	@grep '^version' crates/Cargo.toml | head -1
	@echo "Press Ctrl-C in the next 5 seconds to abort."
	@sleep 5
	cd crates/lion-core && cargo publish
