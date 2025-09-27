# Stage 7 — CI/CD, documentation build, and release gating

Goal
- Provide CI/CD scaffolding to build the DistPOS docs and distpos-tests crate.
- Define release gates and acceptance criteria across stages.
- Keep tests ignored until corresponding features are implemented, while ensuring compilation and docs integrity.

Authoritative inputs
- Stage plan and acceptance checkpoints — [DistPOS_docs/stages.txt](../../DistPOS_docs/stages.txt)
- Test suite (CI gating section) — [DistPOS_docs/test_suit_DistPOS.txt](../../DistPOS_docs/test_suit_DistPOS.txt)

Test sources for CI mapping
- [crates/distpos-tests/](../../crates/distpos-tests/)
  - Stage-7 CI checks (placeholders):
    - [Rust.fn stage7_ci_runner_invocation_and_artifacts()](../../DistPOS_docs/test_suit_DistPOS.txt:151)
    - [Rust.fn stage7_release_gate_conditions_documented()](../../DistPOS_docs/test_suit_DistPOS.txt:153)

Scope and deliverables
- CI workflow (to be added later under .github/workflows/distpos.yml):
  - Steps:
    - Checkout repository
    - Set Rust toolchain (stable + rustfmt + clippy)
    - cargo build -p distpos-tests
    - Build docs/distpos (project docs system)
    - Run link checker across [docs/distpos/README.md](./README.md) and stage docs
  - Do not run ignored tests yet
- Release gates (“Definition of Done” across project):
  - Tests (once enabled):
    - “Happy path” tests for stages 1–3 and 5 must pass: suite 1.x–3.x, 5.x
    - Recovery invariants: zero divergence across crash/restart (suite 9.x)
  - Performance:
    - Throughput/latency thresholds documented and within bounds (suite 7.1–7.4)
  - Security/resilience:
    - All negative/security cases pass without panics or state divergence (suite 8.x)
- Artifacts (to be captured once the harness is implemented):
  - Node logs per run
  - Metrics snapshots (Prometheus scrape)
  - JUnit-style report for tests and basic perf numbers

How to use in local development (once CI files are added)
- Build tests crate without running tests:
  - cargo build -p distpos-tests
- Render docs:
  - See project docs system; start at [docs/distpos/README.md](./README.md)
- Run ignored tests locally (selectively), once some features land:
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage1_
  - cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact stage3_

Release gate criteria (restated from the suite)
- CI/CD automation: [Rust.fn stage7_ci_runner_invocation_and_artifacts()](../../DistPOS_docs/test_suit_DistPOS.txt:151)
  - Build succeeds for distpos-tests
  - Docs build and link-check pass for docs/distpos pages
- Release gates declared and documented: [Rust.fn stage7_release_gate_conditions_documented()](../../DistPOS_docs/test_suit_DistPOS.txt:153)
  - 99% happy-path success (1.x–3.x, 5.x)
  - No state divergence on crash/restart (9.x)
  - Perf thresholds respected: TPS degradation ≤ X%, p95 latency ≤ Y sec (7.x)
  - Negative/security tests: all pass without panics or leaks (8.x)

Notes
- CI is introduced as scaffolding first; execution of ignored tests is deferred until stage features are implemented.
- When enabling tests, gate execution by stage name filters (stage1_, stage2_, …) to control rollout.