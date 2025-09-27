# Stage 3 — Interchain routing, Merkle proof verification, ExEx hook-up

Goal
- Deliver interchain transaction routing between Chain A and Chain B.
- Implement Merkle-proof request/response and verification gating before inclusion on the target chain.
- Expose convenience RPCs for sending and monitoring cross-chain transfers.
- Connect Execution Extensions (ExEx) to observe source-chain events (e.g., Bridge lock) and trigger outbound messages.

Authoritative inputs
- TRD Stage 3 — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - RPC: [Rust.DistPOS_sendCrossChainTransaction(chain,to,data,value)](../../DistPOS_docs/DistPOS_TRD.txt:17)
  - Debug/ops RPCs: [Rust.DistPOS_getPendingProofs()](../../DistPOS_docs/DistPOS_TRD.txt:16), [Rust.DistPOS_provideProof(...)](../../DistPOS_docs/DistPOS_TRD.txt:16), [Rust.DistPOS_getCrossChainStatus(tx_hash)](../../DistPOS_docs/DistPOS_TRD.txt:17)
  - P2P messages for proof exchange in the DistPOS subprotocol
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Stage plan summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)

Test sources (#[ignore] placeholders until implementation lands)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - [Rust.fn stage3_cross_chain_transfer_basic()](../../DistPOS_docs/test_suit_DistPOS.txt:48)
  - [Rust.fn stage3_insufficient_corr_balance_release_reverts()](../../DistPOS_docs/test_suit_DistPOS.txt:51)
  - [Rust.fn stage3_invalid_proof_rejected()](../../DistPOS_docs/test_suit_DistPOS.txt:54)
  - [Rust.fn stage3_routing_via_alternate_node()](../../DistPOS_docs/test_suit_DistPOS.txt:57)
  - [Rust.fn stage3_proof_timeout_expires()](../../DistPOS_docs/test_suit_DistPOS.txt:60)
  - [Rust.fn stage3_cross_chain_batch_sends()](../../DistPOS_docs/test_suit_DistPOS.txt:63)
  - [Rust.fn stage3_source_chain_reorg_handled()](../../DistPOS_docs/test_suit_DistPOS.txt:66)

Scope and deliverables
- Routing and addressing:
  - Interpret target chain-id and route via DistPOS subprotocol to known bootnodes for the target chain.
  - Maintain routing tables per chain (assets added separately).
- Proof exchange:
  - Target chain sends MerkleProofRequest(tx_hash).
  - Source chain responds with MerkleProofResponse(tx_hash, block_header, merkle_proof).
  - Target chain verifies header authenticity and Merkle inclusion against trusted checkpoints.
- Pending/Verified lifecycle:
  - External tx enters PendingProof state until proof is validated.
  - Verified moves to inclusion eligibility; expired on timeout -> rejection.
- ExEx integration:
  - Observe source chain Bridge lock events and trigger outbound CrossTransaction messages.
- RPCs:
  - [Rust.DistPOS_sendCrossChainTransaction()](../../DistPOS_docs/DistPOS_TRD.txt:17) to initiate cross-chain.
  - [Rust.DistPOS_getPendingProofs()](../../DistPOS_docs/DistPOS_TRD.txt:16), [Rust.DistPOS_provideProof()](../../DistPOS_docs/DistPOS_TRD.txt:16) for debug/manual injection.
  - [Rust.DistPOS_getCrossChainStatus()](../../DistPOS_docs/DistPOS_TRD.txt:17) to track progress.

Test scenarios and expected behavior
1) Basic cross-chain transfer A→B
   - [Rust.fn stage3_cross_chain_transfer_basic()](../../DistPOS_docs/test_suit_DistPOS.txt:48)
   - Lock on A; request proof on B; on valid proof, release on B; check balances and corr-account.

2) Insufficient corr-account balance
   - [Rust.fn stage3_insufficient_corr_balance_release_reverts()](../../DistPOS_docs/test_suit_DistPOS.txt:51)
   - Dry-run of release reverts; target node refuses inclusion.

3) Invalid proof rejected
   - [Rust.fn stage3_invalid_proof_rejected()](../../DistPOS_docs/test_suit_DistPOS.txt:54)
   - Any modification to proof bytes leads to rejection and no inclusion.

4) Alternate routing
   - [Rust.fn stage3_routing_via_alternate_node()](../../DistPOS_docs/test_suit_DistPOS.txt:57)
   - Unavailable first peer → switch to alternate from routing table; delivery succeeds.

5) Proof timeout
   - [Rust.fn stage3_proof_timeout_expires()](../../DistPOS_docs/test_suit_DistPOS.txt:60)
   - If no proof within TTL, mark as expired; allow refund/cancel flow as designed.

6) Batch sends
   - [Rust.fn stage3_cross_chain_batch_sends()](../../DistPOS_docs/test_suit_DistPOS.txt:63)
   - 10–50 sequential sends: maintain correlation and ordering; no proof/tx loss.

7) Source-chain reorg handling
   - [Rust.fn stage3_source_chain_reorg_handled()](../../DistPOS_docs/test_suit_DistPOS.txt:66)
   - Reject proofs from non-final blocks; accept after re-finalization.

How to run tests (when enabled)
- Full:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage3_
- Single:
  - cargo test -p distpos-tests --lib stage3_invalid_proof_rejected -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- Pending→Verified→Included lifecycle enforced with cryptographic proof checks.
- RPCs return accurate statuses; manual proof injection works in dev.
- ExEx hooks populate outbound queue on source-chain events.
- All Stage 3 tests pass using Stage 0 topology and assets.

Notes
- Full light-client validation of the foreign validator set is out of scope for this stage; we rely on configured checkpoints and header authenticity checks sufficient for development nets.