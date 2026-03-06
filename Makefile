SHELL := bash

TERRAFORM_VERSION := 1.14.5

.PHONY: help bootstrap install-tools check-tools print-toolchain install-dev-tools precommit-install precommit-run lint format format-check repo-lint repo-format repo-format-check

help:
	@echo "Targets:"
	@echo "  bootstrap         Install toolchain when possible and run baseline setup"
	@echo "  install-tools     Install pinned tools with mise/asdf if available"
	@echo "  check-tools       Validate pinned tool versions"
	@echo "  print-toolchain   Print pinned tool versions"
	@echo "  install-dev-tools Install Python development tooling"
	@echo "  precommit-install Install git pre-commit hooks"
	@echo "  precommit-run     Run the configured pre-commit checks on all files"
	@echo "  lint              Run repo lint checks"
	@echo "  format            Apply repo formatting"
	@echo "  format-check      Check repo formatting without writing changes"

bootstrap: install-tools check-tools install-dev-tools
	@echo "Bootstrap completed."

install-tools:
	@if command -v mise >/dev/null 2>&1; then \
		echo "Installing pinned tools with mise..."; \
		mise install; \
	elif command -v asdf >/dev/null 2>&1; then \
		echo "Installing pinned tools with asdf..."; \
		asdf install; \
	else \
		echo "No supported version manager detected. Validating local tools only."; \
	fi

check-tools:
	@actual_terraform="$$(terraform version 2>/dev/null | head -n 1 || true)"; \
	if [[ -z "$$actual_terraform" ]]; then \
		echo "Terraform is required but not installed. Expected $(TERRAFORM_VERSION)." >&2; \
		exit 1; \
	fi; \
	if [[ "$$actual_terraform" != *"$(TERRAFORM_VERSION)"* ]]; then \
		echo "Terraform version mismatch. Expected $(TERRAFORM_VERSION), got: $$actual_terraform" >&2; \
		exit 1; \
	fi

print-toolchain:
	@echo "Terraform $(TERRAFORM_VERSION)"

install-dev-tools:
	python -m pip install --user -r requirements-dev.txt

precommit-install: install-dev-tools
	python -m pre_commit install

precommit-run:
	python -m pre_commit run --all-files --show-diff-on-failure

lint: repo-lint

format: repo-format

format-check: repo-format-check

repo-lint:
	@echo "No Terraform lint checks are configured in the Phase 1 baseline."

repo-format:
	@echo "No Terraform formatter is configured in the Phase 1 baseline."

repo-format-check:
	@echo "No Terraform format check is configured in the Phase 1 baseline."
