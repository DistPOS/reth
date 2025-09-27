# Stage 1 — PoS core (staking, slashing, validator selection, RPC)

Goal
- Introduce DistPOS consensus basics for a private testnet: validator staking, validator signature checks, basic leader rotation, and slashing path visibility.
- Expose initial RPCs for staking and validator status queries.

Authoritative inputs
- TRD Stage 1 — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - RPCs: [Rust.DistPOS_stake()](../../DistPOS_docs/DistPOS_TRD.txt:5), [Rust.DistPOS_validatorStatus()](../../DistPOS_docs/DistPOS_TRD.txt:5)
  - Consensus module and validations described in TRD “Этап 1”
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Stage plan summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)

Test sources (all start as #[ignore] placeholders)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - [Rust.fn stage1_register_validator()](../../DistPOS_docs/test_suit_DistPOS.txt:9)
  - [Rust.fn stage1_round_robin_block_production()](../../DistPOS_docs/test_suit_DistPOS.txt:14)
  - [Rust.fn stage1_reject_block_without_stake()](../../DistPOS_docs/test_suit_DistPOS.txt:17)
  - [Rust.fn stage1_slashing_double_sign()](../../DistPOS_docs/test_suit_DistPOS.txt:20)
  - [Rust.fn stage1_stake_crash_restart_consistency()](../../DistPOS_docs/test_suit_DistPOS.txt:23)

Scope and deliverables
- Consensus module (DistPOSConsensus) plugged via Node Builder (implementation arrives later):
  - Validate block signatures are from active validators with nonzero stake
  - Maintain slashed flag and exclude slashed validators from producing/validating blocks
- Storage/API extension (initial shape):
  - Validator stake view; slashing markers persisted
  - RPC methods:
    - [Rust.DistPOS_stake()](../../DistPOS_docs/DistPOS_TRD.txt:5): submit deposit/stake for validator
    - [Rust.DistPOS_validatorStatus()](../../DistPOS_docs/DistPOS_TRD.txt:5): query validator stake/active/slashed
- Genesis fixture support:
  - Initial validator set configurable in genesis or via stake RPCs during dev/testing

Test scenarios and expected behavior
1) Register validator
   - [Rust.fn stage1_register_validator()](../../DistPOS_docs/test_suit_DistPOS.txt:9)
   - Call [Rust.DistPOS_stake()](../../DistPOS_docs/DistPOS_TRD.txt:5) to deposit stake for node A
   - Expect A appears in validator set; A can start proposing blocks

2) Round-robin block production
   - [Rust.fn stage1_round_robin_block_production()](../../DistPOS_docs/test_suit_DistPOS.txt:14)
   - With validators A,B,C,D running, blocks rotate fairly (dev round-robin acceptable)
   - Expect liveness and correct signer per block

3) Reject block without stake
   - [Rust.fn stage1_reject_block_without_stake()](../../DistPOS_docs/test_suit_DistPOS.txt:17)
   - Remove stake (or start a node with zero stake); its block proposals are rejected

4) Slashing for double-sign
   - [Rust.fn stage1_slashing_double_sign()](../../DistPOS_docs/test_suit_DistPOS.txt:20)
   - Simulate double-sign from A at the same height
   - Expect slashing event applied exactly once and A excluded from validator set

5) Crash/Restart stake consistency
   - [Rust.fn stage1_stake_crash_restart_consistency()](../../DistPOS_docs/test_suit_DistPOS.txt:23)
   - Restart node mid-application of slashing
   - Expect state consistent after restart (no duplicate application)

How to run tests (when enabled)
- Run the Stage 1 group (ignored by default until implementation is ready):
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage1_
- Run a single test:
  - cargo test -p distpos-tests --lib stage1_register_validator -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- RPCs exposed and callable in the test harness:
  - [Rust.DistPOS_stake()](../../DistPOS_docs/DistPOS_TRD.txt:5) deposits result in active validator entries
  - [Rust.DistPOS_validatorStatus()](../../DistPOS_docs/DistPOS_TRD.txt:5) reports accurate stake and slashed flag
- Consensus enforcement:
  - Only active validators produce valid blocks; slashed validators are refused
  - Double-sign leads to a single slashing application and exclusion
- Tests:
  - All Stage 1 tests pass locally with the dev topology from Stage 0
- Documentation:
  - This page (stage1.md) and the index [docs/distpos/README.md](./README.md) cross-reference the suite and TRD

Notes and linkage
- Slashing transactions may later route through a Staking smart contract (Stage 5). For Stage 1, off-chain or system transaction approaches are acceptable as long as state is consistent and auditable in logs.
- Execution semantics (EVM) remain unchanged at this stage; only consensus acceptance rules differ.