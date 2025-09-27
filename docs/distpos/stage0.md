# Stage 0 — Environment, Topology, and Fixtures

Goal
- Establish a reproducible local environment and dual-network topology (Chain A / Chain B), with genesis/chainspec fixtures and observability hooks.
- Prepare the test harness to exercise Stage 0 checks before core features are implemented.

Authoritative inputs
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- TRD (requirements) — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
- Stage summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)
- Test Suite — [DistPOS_docs/test_suit_DistPOS.txt](../../DistPOS_docs/test_suit_DistPOS.txt)

Test sources
- DistPOS tests crate — [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
- Stage 0 functions (all are initially #[ignore]):
  - [Rust.fn stage0_topology_fixture_sanity()](../../DistPOS_docs/test_suit_DistPOS.txt:3)
  - [Rust.fn stage0_genesis_assets_present()](../../DistPOS_docs/test_suit_DistPOS.txt:4)
  - [Rust.fn stage0_metrics_and_artifacts_wiring()](../../DistPOS_docs/test_suit_DistPOS.txt:5)
  - [Rust.fn stage0_fault_injection_controls_available()](../../DistPOS_docs/test_suit_DistPOS.txt:6)

What this stage sets up
- Local multi-node topology:
  - 4–7 nodes per chain (minimum viable: A:4, B:4)
  - Two independent networks (Chain A, Chain B) with distinct chain-id values
- Genesis/chainspec fixtures (initial placeholders; content will be added in the assets step):
  - Chain A: genesis.chainA.json, chainspec.chainA.toml
  - Chain B: genesis.chainB.json, chainspec.chainB.toml
- Routing tables (placeholders; content will be added in the assets step):
  - routes.chainA.json, routes.chainB.json
- Observability:
  - Metrics endpoint (Prometheus) and simple KPIs (TPS, p95)
  - Artifacts collection: node logs, state roots, database snapshots (optional)

How to run the Stage 0 tests
- Tests are ignored by default to keep the build green. Once basic scaffolding lands, enable them locally with:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage0_
- Individual tests (when enabled):
  - cargo test -p distpos-tests --lib stage0_topology_fixture_sanity -- --include-ignored --ignored --nocapture

What each Stage 0 test should verify (expected behavior)
1) Topology fixture sanity
   - Function: [Rust.fn stage0_topology_fixture_sanity()](../../DistPOS_docs/test_suit_DistPOS.txt:3)
   - Expected:
     - N nodes boot successfully on Chain A; same for Chain B
     - Peering established within each chain; no cross-chain peering
     - Nodes progress to producing empty blocks (baseline dev configs)
2) Genesis assets present
   - Function: [Rust.fn stage0_genesis_assets_present()](../../DistPOS_docs/test_suit_DistPOS.txt:4)
   - Expected:
     - Genesis/chainspec files exist for both chains
     - JSON/TOML parse successfully; IDs/names are coherent
3) Metrics and artifacts wiring
   - Function: [Rust.fn stage0_metrics_and_artifacts_wiring()](../../DistPOS_docs/test_suit_DistPOS.txt:5)
   - Expected:
     - Metrics endpoint responds (HTTP 200)
     - Basic counters present (e.g., block height, peer count)
     - Artifacts directories exist and are writable (logs/snapshots locations)
4) Fault injection controls available
   - Function: [Rust.fn stage0_fault_injection_controls_available()](../../DistPOS_docs/test_suit_DistPOS.txt:6)
   - Expected:
     - Harness exposes knobs to inject latency/drop/partition in the DistPOS subprotocol channel(s)
     - No-ops now, with shape validated (will be exercised later in Stage 6)

Linkage to later stages
- Stage 1 (PoS Core) will use this topology to validate staking/round-robin and slashing invariants.
- Stage 2 (Underwriting) will reuse fault injection to test recovery/timeouts on endorsement requests.
- Stage 3 (Interchain) will require ExEx triggers and dual-chain routing; the same topology expands with cross-chain proof requests.

Acceptance checklist for Stage 0 (internal)
- Test skeleton compiles and is discoverable:
  - [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs) exposes stage0_* tests and maps to the suite anchors
- Documentation present and cross-linked:
  - This page — [docs/distpos/stage0.md](./stage0.md)
  - Index page — [docs/distpos/README.md](./README.md)
- Assets placeholders (to be delivered in assets step):
  - Chain A/B genesis and chainspec templates
  - Routing tables
- Harness interface (placeholders in code, to be implemented next iterations):
  - spawn_network / spawn_dual_network
  - metrics scrape + artifact collection hooks
  - fault injection API surface

References to TRD
- ExEx hook-ups for interchain events and system transactions are introduced in later stages; Stage 0 only ensures the environment:
  - Interchain overview — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - Execution Extensions (concept) — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)

Notes
- Keep Stage 0 tests as “smoke” only — avoid performing substantive consensus logic here.
- Enable individual tests gradually once the corresponding harness utilities are implemented.