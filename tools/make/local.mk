# Local Makefile targets for dockers/node
# Node.js-specific commands and validation

##
## —— 🔍 Local Validation ——
.PHONY: validate
validate: ## Validate configuration files and scripts
	@bash scripts/validate-config.sh

.PHONY: validate-all
validate-all: validate quality ## Run all validation checks (config + quality)

.PHONY: ci-local
ci-local: validate-all bats ## Full local validation (validate + quality + tests)
	@echo "✅ Local validation passed"
