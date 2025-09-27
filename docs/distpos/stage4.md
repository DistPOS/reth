# Stage 4 — Reputation model (nodes and chains) + policy hooks

Goal
- Introduce a reputation system that tracks node and chain behavior and influences protocol decisions.
- Expose RPCs to query and (for dev/testing) set reputation.
- Connect policy hooks in txpool, underwriting, and interchain acceptance.

Authoritative inputs
- TRD Stage 4 — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - RPCs: 
    - [Rust.DistPOS_getNodeReputation(node_address)](../../DistPOS_docs/DistPOS_TRD.txt:23)
    - [Rust.DistPOS_getChainReputation(chain_id)](../../DistPOS_docs/DistPOS_TRD.txt:23)
    - [Rust.DistPOS_setReputation(target,value)](../../DistPOS_docs/DistPOS_TRD.txt:23) (dev/test only)
  - Reputation signals and integration points described in “Этап 4”
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Stage plan summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)

Test sources (#[ignore] placeholders until implementation lands)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - [Rust.fn stage4_reputation_accumulates_honest()](../../DistPOS_docs/test_suit_DistPOS.txt:71)
  - [Rust.fn stage4_reputation_drops_for_violations()](../../DistPOS_docs/test_suit_DistPOS.txt:74)
  - [Rust.fn stage4_chain_reputation_blocks_valid_proof()](../../DistPOS_docs/test_suit_DistPOS.txt:77)
  - [Rust.fn stage4_reputation_recovery()](../../DistPOS_docs/test_suit_DistPOS.txt:80)

Scope and deliverables
- Reputation state
  - Node reputation: address → score (e.g., 0–100), backed by on-disk table for persistence
  - Chain reputation: chain_id → score
  - Event-driven updates from consensus, underwriting, interchain (signals from Stages 1–3)
- RPCs
  - [Rust.DistPOS_getNodeReputation()](../../DistPOS_docs/DistPOS_TRD.txt:23), [Rust.DistPOS_getChainReputation()](../../DistPOS_docs/DistPOS_TRD.txt:23)
  - [Rust.DistPOS_setReputation()](../../DistPOS_docs/DistPOS_TRD.txt:23) for dev/testing scenarios only
- Policy hooks
  - Txpool: prefer transactions from higher-rep senders under contention; throttle spam from low-rep sources
  - Underwriting: prioritize sending [Rust.UnderwriteRequest](../../DistPOS_docs/DistPOS_TRD.txt:12) to higher-rep endorsers; endorsers can refuse low-rep senders
  - Interchain: block or delay external transactions from chains with reputation below threshold

Test scenarios and expected behavior
1) Accumulate honest reputation
   - [Rust.fn stage4_reputation_accumulates_honest()](../../DistPOS_docs/test_suit_DistPOS.txt:71)
   - After N blocks with compliant behavior, small positive increments accumulate across validators

2) Drop reputation for violations
   - [Rust.fn stage4_reputation_drops_for_violations()](../../DistPOS_docs/test_suit_DistPOS.txt:74)
   - Simulate spam underwriting or double-sign attempt → reputation decreases, reflected in RPC reads

3) Chain reputation blocks acceptance
   - [Rust.fn stage4_chain_reputation_blocks_valid_proof()](../../DistPOS_docs/test_suit_DistPOS.txt:77)
   - With chain A reputation set low, a valid Merkle proof from A is rejected by the policy layer on B

4) Recovery over time
   - [Rust.fn stage4_reputation_recovery()](../../DistPOS_docs/test_suit_DistPOS.txt:80)
   - With no further violations, a decay/recovery policy gradually restores some score

How to run tests (when enabled)
- All Stage 4 tests:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage4_
- Single test:
  - cargo test -p distpos-tests --lib stage4_chain_reputation_blocks_valid_proof -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- Reputation state persists across restarts; RPCs report accurate values
- Txpool/Underwriting/Interchain policies read reputation and alter behavior deterministically
- Dev-setter RPC guarded to test-only paths or feature flags
- All Stage 4 tests pass in Stage 0 topology

Notes and linkage
- Reputation can be mirrored on-chain later (optional), but the core mechanism is off-chain within the node at this stage.
- Reputation thresholds must not cause liveness failures; policies should degrade gracefully and be configurable.