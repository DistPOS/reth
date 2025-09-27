# Stage 5 — Smart contracts (Staking, Bridge, Cross-call); genesis integration; ExEx glue

Goal
- Move critical protocol checks to smart contracts for transparency and upgradeability:
  - Staking/Slashing contract for validator deposits and penalties
  - Bridge contracts for cross-chain value movement via correspondent accounts
  - Optional CrossChainCall contract for executing msg.data on the target chain
- Predeploy contracts via genesis and wire node-side system transactions and read-paths.
- Integrate ExEx hooks to observe source-chain events and to materialize target-side actions.

Authoritative inputs
- TRD Stage 5 — [DistPOS_docs/DistPOS_TRD.txt](../../DistPOS_docs/DistPOS_TRD.txt)
  - Staking: [Solidity.StakingContract.slash()](../../DistPOS_docs/DistPOS_TRD.txt:36)
  - Bridge (target side): [Solidity.BridgeFromA.release()](../../DistPOS_docs/DistPOS_TRD.txt:39)
  - Cross-call: [Solidity.CrossChainCallContract.execute(bytes)](../../DistPOS_docs/DistPOS_TRD.txt:41)
  - Genesis predeployment, protocol/system tx, StateProvider read-paths, ExEx integration
- Project description — [DistPOS_docs/DistPos_descr.txt](../../DistPOS_docs/DistPos_descr.txt)
- Stage plan summary — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)

Test sources (#[ignore] placeholders until implementation lands)
- [crates/distpos-tests/src/lib.rs](../../crates/distpos-tests/src/lib.rs)
  - [Rust.fn stage5_staking_contract_deposit_and_slash()](../../DistPOS_docs/test_suit_DistPOS.txt:85)
  - [Rust.fn stage5_bridge_lock_release_happy_path_with_msg_data()](../../DistPOS_docs/test_suit_DistPOS.txt:88)
  - [Rust.fn stage5_bridge_release_denied_by_conditions()](../../DistPOS_docs/test_suit_DistPOS.txt:91)
  - [Rust.fn stage5_system_contract_addresses_in_genesis_and_upgrade()](../../DistPOS_docs/test_suit_DistPOS.txt:94)

Scope and deliverables
- Contracts
  - StakingContract
    - stake(), unstake(), [Solidity.StakingContract.slash()](../../DistPOS_docs/DistPOS_TRD.txt:36)
    - Only protocol/system authority can slash (dev mode: privileged account)
  - Bridge contracts
    - Source chain (BridgeToB.lock): lock funds and emit event
    - Target chain (BridgeFromA.release): verify policy, reduce correspondent balance, credit recipient; optional call to CrossChainCall
  - CrossChainCallContract.execute(bytes data)
    - Decode data to target address + payload and perform target.call(payload)
- Genesis integration
  - Predeploy contracts at reserved addresses (e.g., 0x...1001, 0x...1002, ...)
  - Record addresses in chainspec/genesis templates (added in the assets step)
- Node integration
  - System/protocol tx for slashing and release
  - Read-only calls to contracts (StateProvider) for validation checks (e.g., BridgeFromA.balanceOf(chainA))
  - ExEx hook to notice BridgeToX.lock events and trigger CrossTransaction towards target chain

Test scenarios and expected behavior
1) Staking deposit and slash
   - [Rust.fn stage5_staking_contract_deposit_and_slash()](../../DistPOS_docs/test_suit_DistPOS.txt:85)
   - Deposit for validator; invoke slash via system tx; storage reflects decreased stake; exactly-once semantics across restarts

2) Bridge lock/release happy path (with msg.data)
   - [Rust.fn stage5_bridge_lock_release_happy_path_with_msg_data()](../../DistPOS_docs/test_suit_DistPOS.txt:88)
   - On chain A: BridgeToB.lock(user, amount, B, recipient, data) emits event
   - ExEx observes event, triggers outbound CrossTransaction
   - On chain B: node prepares BridgeFromA.release(recipient, amount, proof/data), dry-runs; if pass, include and ensure atomicity (credit + optional target.call(payload))

3) Bridge release denied by conditions
   - [Rust.fn stage5_bridge_release_denied_by_conditions()](../../DistPOS_docs/test_suit_DistPOS.txt:91)
   - Insufficient correspondent balance or invalid data → release reverts in dry-run; node refuses inclusion

4) System contract addresses in genesis and upgrade
   - [Rust.fn stage5_system_contract_addresses_in_genesis_and_upgrade()](../../DistPOS_docs/test_suit_DistPOS.txt:94)
   - Address set correctness validated at startup
   - Simulated upgrade: nodes disagreeing on address should fail to finalize conflicting blocks → demonstrates need for coordinated upgrade

How to run tests (when enabled)
- Full Stage 5 group:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage5_
- Single:
  - cargo test -p distpos-tests --lib stage5_bridge_lock_release_happy_path_with_msg_data -- --include-ignored --ignored --nocapture

Acceptance criteria (Definition of Done)
- Contracts deployed via genesis; addresses known to nodes and tests
- Slashing and release materialized in block execution (system tx path implemented)
- Read-only checks for Bridge balances and policies enforce correctness (revert on failure)
- End-to-end cross-chain with contract release and optional cross-call passes
- All Stage 5 tests pass in Stage 0 topology across two chains

Notes and linkage
- On-chain proof verification is intentionally kept off this stage due to gas costs; nodes verify proofs off-chain, contracts enforce policy and balances.
- Future upgrades can adjust penalty formulae and release policies by redeploying/upgrading contracts and updating chainspecs consistently.