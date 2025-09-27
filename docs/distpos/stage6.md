# Stage 6 — End-to-end integration, performance, adversarial, and recovery

Goal
- Validate network resilience and performance under load, message loss/duplication, partitions, and restarts.
- Establish quantitative KPIs (TPS, p95 latency) and resource ceilings (memory/disk) under test.
- Exercise negative/security scenarios and recovery invariants.

Authoritative inputs
- TRD stages 3–5 are prerequisites for full e2e; this stage focuses on system behavior and metrics
  - Interchain + proofs: see [docs/distpos/stage3.md](./stage3.md)
  - Contracts + ExEx glue: see [docs/distpos/stage5.md](./stage5.md)
- Suite (scenarios and pass criteria) — [DistPOS_docs/test_suit_DistPOS.txt](../../DistPOS_docs/test_suit_DistPOS.txt)

Test sources (#[ignore] placeholders until implementation lands)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - Failures/resilience:
    - [Rust.fn stage6_network_partition_reconverges()](../../DistPOS_docs/test_suit_DistPOS.txt:98)
    - [Rust.fn stage6_message_loss_and_duplicates_idempotent()](../../DistPOS_docs/test_suit_DistPOS.txt:102)
    - [Rust.fn stage6_restart_nodes_under_load_recovery()](../../DistPOS_docs/test_suit_DistPOS.txt:105)
  - Performance/scaling:
    - [Rust.fn stage6_tps_local_transactions_baseline()](../../DistPOS_docs/test_suit_DistPOS.txt:110)
    - [Rust.fn stage6_underwriting_overhead_latency()](../../DistPOS_docs/test_suit_DistPOS.txt:113)
    - [Rust.fn stage6_cross_chain_throughput()](../../DistPOS_docs/test_suit_DistPOS.txt:116)
    - [Rust.fn stage6_memory_disk_growth_no_leak()](../../DistPOS_docs/test_suit_DistPOS.txt:119)
  - Security/negative (grouped here for runner convenience):
    - [Rust.fn stage8_replay_duplicate_proof_detected()](../../DistPOS_docs/test_suit_DistPOS.txt:124)
    - [Rust.fn stage8_chain_id_spoof_detected()](../../DistPOS_docs/test_suit_DistPOS.txt:127)
    - [Rust.fn stage8_sybil_endorsers_blocked()](../../DistPOS_docs/test_suit_DistPOS.txt:130)
    - [Rust.fn stage8_endorsing_dos_rate_limited()](../../DistPOS_docs/test_suit_DistPOS.txt:133)
    - [Rust.fn stage8_invalid_system_tx_block_rejected()](../../DistPOS_docs/test_suit_DistPOS.txt:136)
  - Recovery/consistency:
    - [Rust.fn stage9_crash_mid_block_single_effect()](../../DistPOS_docs/test_suit_DistPOS.txt:141)
    - [Rust.fn stage9_reorg_aware_underwriting_reassess()](../../DistPOS_docs/test_suit_DistPOS.txt:144)
    - [Rust.fn stage9_pending_queues_persisted()](../../DistPOS_docs/test_suit_DistPOS.txt:147)

Scope and deliverables
- Fault injection
  - Programmatic partitioning (A|B,C,D), message delay/drop/duplication for DistPOS subprotocols
  - Node restarts under load, with reconstruction of in-flight queues (endorsements/proofs)
- Metrics
  - Prometheus scraping for TPS and p95 block confirm latency
  - Resource tracking: memory growth and disk usage over long runs
- Security neg-tests
  - Prevent replay/duplicate proof acceptance
  - Enforce chain-id integrity on interchain messages
  - Throttle/deny Sybil endorsement attacks; rate-limit endorsing DoS
  - Reject malformed “system” transactions at block validation

Scenarios and expected behavior
1) Network partition reconverges
   - [Rust.fn stage6_network_partition_reconverges()](../../DistPOS_docs/test_suit_DistPOS.txt:98)
   - After partition and independent block production, network heals and finalizes one canonical history without dual finals.

2) Message loss/duplicates idempotent
   - [Rust.fn stage6_message_loss_and_duplicates_idempotent()](../../DistPOS_docs/test_suit_DistPOS.txt:102)
   - Underwrite*/Merkle* messages survive 30% drop and duplication without deadlocks or double-apply.

3) Restart under load
   - [Rust.fn stage6_restart_nodes_under_load_recovery()](../../DistPOS_docs/test_suit_DistPOS.txt:105)
   - Node restarts restore pending endorsements/proofs and resume progress.

4) TPS baseline for local txs
   - [Rust.fn stage6_tps_local_transactions_baseline()](../../DistPOS_docs/test_suit_DistPOS.txt:110)
   - Baseline not worse than reference minus allowed deviation; report TPS and p95.

5) Underwriting overhead
   - [Rust.fn stage6_underwriting_overhead_latency()](../../DistPOS_docs/test_suit_DistPOS.txt:113)
   - Latency increases linearly/sublinearly with endorsers; no timeouts under normal load.

6) Cross-chain throughput
   - [Rust.fn stage6_cross_chain_throughput()](../../DistPOS_docs/test_suit_DistPOS.txt:116)
   - Stable queue with bounded latency and no loss.

7) Memory/disk growth
   - [Rust.fn stage6_memory_disk_growth_no_leak()](../../DistPOS_docs/test_suit_DistPOS.txt:119)
   - No memory leaks; predictable DB growth given queue sizes.

8) Security negatives
   - [Rust.fn stage8_*](../../DistPOS_docs/test_suit_DistPOS.txt:124)
   - Replays/spoofing/Sybil/DoS/system-tx injection all correctly denied.

9) Recovery and state consistency
   - [Rust.fn stage9_*](../../DistPOS_docs/test_suit_DistPOS.txt:141)
   - Exactly-once effects across crash/restart; reorg-aware underwriting re-evaluates; pending queues persisted.

How to run tests (when enabled)
- Entire Stage 6 group (including 8/9 when grouped under this runner):
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage6_
- Single scenario:
  - cargo test -p distpos-tests --lib stage6_network_partition_reconverges -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- Fault injection APIs functional and deterministic for tests
- KPIs (TPS, p95) within configured thresholds; resource use acceptable
- Negative/security scenarios pass without panics or state divergence
- Recovery invariants (no double-apply, persisted queues) validated