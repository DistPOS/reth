# DistPOS Implementation Guide

This documentation tracks the staged implementation, tests, and acceptance criteria for integrating DistPOS into Reth.

Authoritative inputs:
- Project description: DistPOS overview — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Technical Requirements (TRD) — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
- Staging/budget summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)
- Test Suite (scenarios and pass criteria) — [DistPOS_docs/test_suit_DistPOS.txt](../../DistPOS_docs/test_suit_DistPOS.txt)

Repo components for tests:
- New integration tests crate — [crates/distpos-tests/](../../crates/distpos-tests/)
  - Tests are mapped 1:1 to the suite and start #[ignore] as placeholders
  - Will be enabled per stage as features are implemented

## Stage index

- Stage 0 — Environment setup and fixtures — [docs/distpos/stage0.md](./stage0.md)
- Stage 1 — PoS core (staking/slashing/round-robin) — [docs/distpos/stage1.md](./stage1.md)
- Stage 2 — Underwriting (endorsements + P2P) — [docs/distpos/stage2.md](./stage2.md)
- Stage 3 — Interchain routing, Merkle proofs, ExEx hooks — [docs/distpos/stage3.md](./stage3.md)
- Stage 4 — Reputation model and policy hooks — [docs/distpos/stage4.md](./stage4.md)
- Stage 5 — Smart contracts (Staking, Bridge, Cross-call) and genesis integration — [docs/distpos/stage5.md](./stage5.md)
- Stage 6 — End-to-end integration, performance, adversarial, and recovery — [docs/distpos/stage6.md](./stage6.md)
- Stage 7 — CI/CD and release gating — [docs/distpos/stage7.md](./stage7.md)

Each stage page includes:
- Scope and deliverables (linked back to the TRD)
- Test cases mapped directly to the suite, with exact line anchors
- Operator instructions and verification steps
- Acceptance criteria and “Definition of Done”

## Acceptance checkpoints per stages (from TRD and stages.txt)

- Stage 1 (PoS core): DistPOS consensus crate active on private testnet; RPCs usable; slashing path observable in state. See [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt) and TRD section “Этап 1”.
- Stage 2 (Underwriting): Underwriting gate enforced; endorsements required beyond local stake; P2P messages functioning across ≥3 nodes. See TRD “Этап 2”.
- Stage 3 (Interchain): Cross-chain A→B with verified Merkle proof gating; status RPCs; atomicity scenarios covered. See TRD “Этап 3”.
- Stage 4 (Reputation): Reputation affects underwriting peer selection and interchain acceptance; RPCs return dynamic scores. See TRD “Этап 4”.
- Stage 5 (Contracts): Contracts deployed in genesis; bridge corr-account checks; cross-call (msg.data) executes on target. See TRD “Этап 5”.
- Stage 6 (E2E+Perf): Stability in long runs; perf and adversarial suites passing thresholds; recovery invariants hold. See test suite sections 6–9.
- Stage 7 (CI/CD): Docs build, crate builds, release gates documented and enforced.

## How to run tests (placeholder)

Until features are implemented, tests are #[ignore] to keep builds green. They will be progressively enabled as the implementation lands.

Examples (to run a stage subset once enabled):
- cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage1_
- cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage3_

Where function names are defined in [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs) and mapped to:
- Suite anchors (e.g., stage3_cross_chain_transfer_basic → [DistPOS_docs/test_suit_DistPOS.txt](../../DistPOS_docs/test_suit_DistPOS.txt))
- TRD APIs/messages (e.g., DistPOS_sendCrossChainTransaction, UnderwriteRequest/Response)

## Conventions and linkage

- Every test in [crates/distpos-tests/](../../crates/distpos-tests/) carries a comment anchor to the source suite line (for traceability) and to the TRD line(s) defining the interface/message/API.
- Documentation pages reference exact items in the suite and in the TRD with explicit file links.
- Operator docs will be expanded per stage with runbooks and troubleshooting when the corresponding features are implemented.

## Next work items

- Add stage pages:
  - stage0.md: environment setup, local topology, genesis fixtures, running selected tests
  - stage1.md..stage7.md: content skeleton per stage, linking to suite and TRD
- Add assets templates (genesis/chainspec/routes) for Chain A/B (will be tracked separately)
- Add CI skeleton to build docs and the tests crate