# Stage 2 — Underwriting (endorsements) + P2P subprotocol + txpool integration

Goal
- Introduce underwriting flow for transactions that exceed the sender’s local stake.
- Add P2P subprotocol messages for collecting endorsements and txpool gating for “await endorsements”.
- Provide RPCs to list endorsements and allow manual participation during testing.

Authoritative inputs
- TRD Stage 2 — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - Messages: [Rust.UnderwriteRequest](../../DistPOS_docs/DistPOS_TRD.txt:12), [Rust.UnderwriteResponse](../../DistPOS_docs/DistPOS_TRD.txt:12)
  - RPCs: [Rust.DistPOS_listEndorsements(tx_hash)](../../DistPOS_docs/DistPOS_TRD.txt:11), [Rust.DistPOS_endorseTransaction(tx_hash)](../../DistPOS_docs/DistPOS_TRD.txt:11)
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Stage plan summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)

Test sources (#[ignore] placeholders until implementation lands)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - [Rust.fn stage2_tx_within_stake_no_endorsements()](../../DistPOS_docs/test_suit_DistPOS.txt:28)
  - [Rust.fn stage2_tx_over_stake_collect_endorsements()](../../DistPOS_docs/test_suit_DistPOS.txt:31)
  - [Rust.fn stage2_endorsement_refusal_timeout()](../../DistPOS_docs/test_suit_DistPOS.txt:34)
  - [Rust.fn stage2_endorsement_cancel_unlocks()](../../DistPOS_docs/test_suit_DistPOS.txt:37)
  - [Rust.fn stage2_invalid_tx_with_endorsements_slash()](../../DistPOS_docs/test_suit_DistPOS.txt:40)
  - [Rust.fn stage2_underwriting_spam_resilience()](../../DistPOS_docs/test_suit_DistPOS.txt:43)

Scope and deliverables
- Txpool admission policy:
  - For tx.value ≤ stake(sender): admit normally.
  - For tx.value > stake(sender): mark as “await endorsements”, not eligible for block inclusion.
- Underwriting P2P subprotocol (DistPOS):
  - Broadcast [Rust.UnderwriteRequest](../../DistPOS_docs/DistPOS_TRD.txt:12) with tx_hash and required stake delta.
  - Accept [Rust.UnderwriteResponse](../../DistPOS_docs/DistPOS_TRD.txt:12) from peers with signatures/endorser IDs.
  - Timeouts and cancellation flows (UnderwriteCancel optional at first; time-based unlock acceptable initially).
- Locked stake accounting:
  - Maintain per-endorser lockedStake to avoid over-commitment.
  - Release on cancel/timeout; finalize on inclusion.
- RPCs for testing/observability:
  - [Rust.DistPOS_listEndorsements(tx_hash)](../../DistPOS_docs/DistPOS_TRD.txt:11): return endorsers and amounts.
  - [Rust.DistPOS_endorseTransaction(tx_hash)](../../DistPOS_docs/DistPOS_TRD.txt:11): manual trigger for dev/testing.

Test scenarios and expected behavior
1) Tx ≤ stake: no endorsements
   - [Rust.fn stage2_tx_within_stake_no_endorsements()](../../DistPOS_docs/test_suit_DistPOS.txt:28)
   - Expect normal inclusion without underwriting round.

2) Tx > stake: collect endorsements
   - [Rust.fn stage2_tx_over_stake_collect_endorsements()](../../DistPOS_docs/test_suit_DistPOS.txt:31)
   - Node A broadcasts [Rust.UnderwriteRequest](../../DistPOS_docs/DistPOS_TRD.txt:12); B,C respond [Rust.UnderwriteResponse](../../DistPOS_docs/DistPOS_TRD.txt:12) with totals ≥ deficit.
   - Tx becomes eligible and is included; B,C show lockedStake updates.

3) Refusal/timeout
   - [Rust.fn stage2_endorsement_refusal_timeout()](../../DistPOS_docs/test_suit_DistPOS.txt:34)
   - No sufficient endorsements arrive within TTL; tx leaves queue or is rejected; A gets negative result.

4) Cancel/unlock
   - [Rust.fn stage2_endorsement_cancel_unlocks()](../../DistPOS_docs/test_suit_DistPOS.txt:37)
   - If tx is dropped or times out, endorsers’ lockedStake is released (timer or explicit cancel).

5) Invalid tx with endorsements → penalties
   - [Rust.fn stage2_invalid_tx_with_endorsements_slash()](../../DistPOS_docs/test_suit_DistPOS.txt:40)
   - If tx is invalid at execution time, apply penalties to the sender and (policy-dependent) endorsers.

6) Spam resilience
   - [Rust.fn stage2_underwriting_spam_resilience()](../../DistPOS_docs/test_suit_DistPOS.txt:43)
   - Rate-limit or reject abusive UnderwriteRequest floods; ensure network stability and responsiveness.

How to run tests (when enabled)
- Full Stage 2 set:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage2_
- Single test:
  - cargo test -p distpos-tests --lib stage2_tx_over_stake_collect_endorsements -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- Txpool gating works:
  - Over-stake txs require endorsements before inclusion.
- P2P message flow functional:
  - Requests/responses exchanged; minimal fanout ok; timeouts supported.
- Locked stake bookkeeping:
  - Increase on endorsement, release on cancel/timeout, settle on inclusion.
- RPCs exposed and returning expected values:
  - [Rust.DistPOS_listEndorsements()](../../DistPOS_docs/DistPOS_TRD.txt:11) shows endorsers; 
  - [Rust.DistPOS_endorseTransaction()](../../DistPOS_docs/DistPOS_TRD.txt:11) triggers local participation in dev mode.
- All Stage 2 tests pass in the Stage 0 topology.

Notes and linkage
- Endorsements can be attached as a meta-envelope in the mempool and reflected in block extraData or via a system tx (format flexible as long as nodes can validate).
- Reputation influences request routing and acceptance later (Stage 4). For Stage 2, keep policies minimal and deterministic.