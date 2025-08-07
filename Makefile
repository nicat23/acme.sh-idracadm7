# Makefile — Dry-run test suite for acme.sh-idracadm7

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────────
# 🧹 Cleanup Targets
# ─────────────────────────────────────────────────────────────

clean:
	@echo "🧹 Cleaning test directories..."
	@PREVIEW=$(PREVIEW) sh test/clean.sh

clean-local:
	@echo "🧹 Cleaning local dev directories..."
	@LE_BASE=$(LE_BASE) PREVIEW=$(PREVIEW) sh test/clean_local.sh

clean-summary:
	@echo "🧹 Cleaning all test paths (dry-run + local override)..."
	@PREVIEW=$(PREVIEW) $(MAKE) clean
	@LE_BASE=$(LE_BASE) PREVIEW=$(PREVIEW) $(MAKE) clean-local
	@echo "✅ All test paths cleaned."

clean-all:
	@echo "🧨 Cleaning all test and dev paths..."
	@PREVIEW=$(PREVIEW) $(MAKE) clean
	@LE_BASE=$(LE_BASE) PREVIEW=$(PREVIEW) $(MAKE) clean-local
	@if [ "$(CONFIRM)" = "true" ]; then \
        if [ -d "$(LE_WORKING_DIR)/acme.sh" ]; then \
            if [ "$(PREVIEW)" = "true" ]; then \
                echo "🔍 Preview: would remove golden reference tree: $(LE_WORKING_DIR)/acme.sh"; \
            else \
                echo "⚠️  Removing golden reference tree: $(LE_WORKING_DIR)/acme.sh"; \
                rm -rf "$(LE_WORKING_DIR)/acme.sh"; \
            fi \
        else \
            echo "ℹ️  No golden reference found — skipping."; \
        fi \
    else \
        echo "🚫 Skipping golden reference cleanup — set CONFIRM=true to enable."; \
    fi
	@echo "✅ All paths cleaned."

preview-clean:
	@echo "🔍 Previewing full cleanup plan..."
	@PREVIEW=true $(MAKE) clean
	@LE_BASE=$(LE_BASE) PREVIEW=true $(MAKE) clean-local
	@if [ -d "$(LE_WORKING_DIR)/acme.sh" ]; then \
        echo "🔍 Preview: would remove golden reference tree: $(LE_WORKING_DIR)/acme.sh"; \
    else \
        echo "ℹ️  No golden reference found — nothing to preview."; \
    fi
	@echo "✅ Preview complete — no paths were deleted."

# ─────────────────────────────────────────────────────────────
# 🔧 Initialization & Debugging
# ─────────────────────────────────────────────────────────────

dryrun-main:
	@echo "🔧 Running full dry-run initialization..."
	@sh test/init_dryrun.sh

debug-tree:
	@echo "🔍 Dumping /tmp/test tree..."
	@tree -pug /tmp/test || echo "⚠️ 'tree' not installed"
	@echo ""
	@echo "🔍 Permissions summary:"
	@find /tmp/test -type f -exec ls -l {} \; | head -n 20

# ─────────────────────────────────────────────────────────────
# 🧪 Test Suite Targets
# ─────────────────────────────────────────────────────────────

validate:
	@echo "🔍 Validating dry-run environment..."
	@sh test/validate.sh

test-fast:
	@echo "⚡ Running fast dry-run test suite..."
	@$(MAKE) dryrun-main
	@$(MAKE) validate
	@$(MAKE) debug-tree
	@echo "✅ Fast test completed."

test-all:
	@echo "🧪 Running full dry-run test suite..."
	@$(MAKE) clean
	@$(MAKE) dryrun-main
	@$(MAKE) validate
	@$(MAKE) debug-tree
	@echo "✅ All tests completed."

test-summary:
	@echo "🧪 Running full dry-run test suite..."
	@sh test/validate.sh || { echo "❌ Validation failed."; exit 1; }
	@sh test/report.sh   || { echo "❌ Report generation failed."; exit 1; }
	@sh test/diff.sh     || { echo "❌ Diff check failed."; exit 1; }
	@echo "✅ All tests passed."

test-summary-json:
	@echo "📊 Validating JSON summary output..."
	@if [ -f /init-summary.json ]; then \
        jq . /init-summary.json || { echo "❌ Invalid JSON format."; exit 1; }; \
        echo "✅ JSON summary is valid."; \
    else \
        echo "❌ Missing /init-summary.json"; \
        exit 1; \
    fi

test-diff:
	@echo "🔍 Running dry-run diff check..."
	@sh test/diff.sh
	@echo "✅ Diff check completed."

test-report:
	@echo "📊 Generating dry-run report..."
	@sh test/report.sh

test-watch:
	@echo "👀 Watching dry-run environment..."
	@sh test/watch.sh

test-sync:
	@echo "🔁 Running sync logic with dry-run and mode support..."
	@sh test/run_sync.sh

test-cleanup:
	@echo "🧹 Asserting cleanup of broken symlinks..."
	@sh test/assert_cleanup.sh

test-missing-dir:
	@echo "🚫 Simulating missing source directory..."
	@sh test/simulate_missing_notify.sh

test-enhanced:
	@echo "🧪 Running enhanced dry-run test suite..."
	@$(MAKE) clean
	@$(MAKE) dryrun-main
	@$(MAKE) test-missing-dir
	@$(MAKE) test-sync
	@$(MAKE) test-cleanup
	@$(MAKE) validate
	@$(MAKE) debug-tree
	@echo "✅ Enhanced test suite completed."

# ─────────────────────────────────────────────────────────────
# 📚 Help Target
# ─────────────────────────────────────────────────────────────

help:
	@echo "🛠️  Available targets:"
	@echo "  make clean             - Remove test directories"
	@echo "  make clean-local       - Remove local dev paths"
	@echo "  make clean-summary     - Remove all test paths (dry-run + local)"
	@echo "  make clean-all         - Remove all paths (dry-run + local + golden) — requires CONFIRM=true"
	@echo "                           Add PREVIEW=true to show what would be deleted"
	@echo "  make preview-clean     - Show what would be deleted by clean-all (dry-run only)"
	@echo "  make dryrun-main       - Run full dry-run initialization"
	@echo "  make debug-tree        - Show /tmp/test tree and file permissions"
	@echo "  make validate          - Validate dry-run environment"
	@echo "  make test-fast         - Run fast dry-run test suite"
	@echo "  make test-all          - Run full dry-run test suite with cleanup"
	@echo "  make test-summary      - Run validation, report, and diff checks"
	@echo "  make test-summary-json - Validate /init-summary.json output"
	@echo "  make test-diff         - Compare dry-run tree to golden reference"
	@echo "  make test-report       - Generate dry-run report"
	@echo "  make test-watch        - Watch dry-run environment for changes"
	@echo "  make test-sync         - Run sync logic with dry-run and copy/symlink mode"
	@echo "  make test-cleanup      - Assert broken symlink cleanup"
	@echo "  make test-missing-dir  - Simulate missing source directory for fallback testing"
	@echo "  make test-enhanced     - Run full enhanced test suite with sync, cleanup, and validation"
	@echo "  make help              - Show this help message"
