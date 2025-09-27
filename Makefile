# DistPOS development Makefile
# Lightweight runners to list and execute stage-tagged ignored tests and collect artifacts.

# Variables
CRATE=distpos-tests
ARTIFACTS_DIR=artifacts/distpos
TIMESTAMP:=$(shell date -u +"%Y%m%dT%H%M%SZ")

.PHONY: help
help:
	@echo "Targets:"
	@echo "  list-tests              - List all tests in crates/distpos-tests, showing ignored flags"
	@echo "  test-stage STAGE=N      - Run all tests for stage N (e.g., N=1), include ignored, exact prefix match"
	@echo "  test-one TEST=name      - Run a single test function (exact match), include ignored"
	@echo "  test-stage0..test-stage7- Convenience targets per stage number"
	@echo "  collect-stage STAGE=N   - Run stage tests and collect logs into artifacts/"
	@echo "Examples:"
	@echo "  make list-tests"
	@echo "  make test-stage STAGE=3"
	@echo "  make test-one TEST=stage1_register_validator"
	@echo "  make collect-stage STAGE=2"

.PHONY: list-tests
list-tests:
	cargo test -p $(CRATE) -- --list

.PHONY: test-stage
test-stage:
ifndef STAGE
	$(error STAGE is not set. Use: make test-stage STAGE=3)
endif
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage$(STAGE)_

.PHONY: test-stage0 test-stage1 test-stage2 test-stage3 test-stage4 test-stage5 test-stage6 test-stage7
test-stage0:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage0_
test-stage1:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage1_
test-stage2:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage2_
test-stage3:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage3_
test-stage4:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage4_
test-stage5:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage5_
test-stage6:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage6_
test-stage7:
	cargo test -p $(CRATE) --lib -- --include-ignored --ignored --exact stage7_

.PHONY: test-one
test-one:
ifndef TEST
	$(error TEST is not set. Use: make test-one TEST=stage1_register_validator)
endif
	cargo test -p $(CRATE) --lib $(TEST) -- --include-ignored --ignored --nocapture

.PHONY: collect-stage
collect-stage:
ifndef STAGE
	$(error STAGE is not set. Use: make collect-stage STAGE=3)
endif
	mkdir -p $(ARTIFACTS_DIR)/stage$(STAGE)/$(TIMESTAMP)
	./scripts/distpos/run-stage.sh $(STAGE) $(ARTIFACTS_DIR)/stage$(STAGE)/$(TIMESTAMP)
