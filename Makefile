SHELL := bash

TERRAFORM_VERSION := 1.14.5

.PHONY: help bootstrap install-tools check-tools print-toolchain

help:
	@echo "Targets:"
	@echo "  bootstrap       Install toolchain when possible and run baseline setup"
	@echo "  install-tools    Install pinned tools with mise/asdf if available"
	@echo "  check-tools      Validate pinned tool versions"
	@echo "  print-toolchain  Print pinned tool versions"

bootstrap: install-tools check-tools
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
