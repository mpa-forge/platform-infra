SHELL := bash

TERRAFORM_VERSION := 1.14.5
LOCAL_COMPOSE_FILE := local/compose.yml
LOCAL_COMPOSE_PROJECT := platform-blueprint-local
BUILD ?=
DOCKER_COMPOSE := docker compose -p $(LOCAL_COMPOSE_PROJECT) -f $(LOCAL_COMPOSE_FILE)
DOCKER_COMPOSE_ALL_PROFILES := $(DOCKER_COMPOSE) --profile frontend-support --profile api-support
DOCKER_BUILD_FLAG := $(if $(filter 1 true TRUE yes YES on ON,$(BUILD)),--build,)

TERRAFORM_VALIDATE_DIRS := \
	environments/rc \
	environments/prod \
	modules/network \
	modules/cloudrun_api \
	modules/gke \
	modules/gar \
	modules/grafana_dashboards \
	modules/cloudsql \
	modules/stack \
	modules/secrets \
	modules/vps_stack \
	modules/observability_support

.PHONY: help bootstrap doctor sync-agent-skills sync-agent-skills-check install-tools check-tools print-toolchain install-dev-tools precommit-install precommit-run lint format format-check repo-lint repo-format repo-format-check repo-policy-check terraform-init terraform-validate terraform-plan terraform-apply local-frontend-support-up local-api-support-up local-full-up local-down local-ps local-frontend-support-logs local-api-support-logs local-full-logs local-smoke-test local-db-reset

help:
	@echo "Targets:"
	@echo "  bootstrap         Install toolchain when possible and run baseline setup"
	@echo "  sync-agent-skills Refresh managed common skills from sibling platform-blueprint-specs"
	@echo "  sync-agent-skills-check Fail if managed common skills drift from sibling platform-blueprint-specs"
	@echo "  doctor            Run shared workstation checks from sibling platform-blueprint-specs"
	@echo "  install-tools     Install pinned tools with mise/asdf if available"
	@echo "  check-tools       Validate pinned tool versions"
	@echo "  print-toolchain   Print pinned tool versions"
	@echo "  install-dev-tools Install Python development tooling"
	@echo "  precommit-install Install git pre-commit hooks"
	@echo "  precommit-run     Run the configured pre-commit checks on all files"
	@echo "  lint              Run repo lint checks"
	@echo "  format            Apply repo formatting"
	@echo "  format-check      Check repo formatting without writing changes"
	@echo "  repo-policy-check Run Terraform and dashboard policy checks"
	@echo "  terraform-init    Run terraform init -backend=false for env roots and shared modules"
	@echo "  terraform-validate Run terraform validate for env roots and shared modules"
	@echo "  terraform-plan ENV=<rc|prod> Run terraform plan for a single environment root"
	@echo "  terraform-apply ENV=<rc|prod> Run terraform apply for a single environment root"
	@echo "  local-frontend-support-up Start postgres + backend-api for native frontend work (optional: BUILD=1)"
	@echo "  local-api-support-up      Start postgres + frontend-web for native API work (optional: BUILD=1)"
	@echo "  local-full-up             Start frontend-web + backend-api + postgres"
	@echo "  local-down                Stop the local development stack"
	@echo "  local-ps                  Show local development stack status"
	@echo "  local-frontend-support-logs Stream postgres + backend-api logs"
	@echo "  local-api-support-logs      Stream postgres + frontend-web logs"
	@echo "  local-full-logs            Stream frontend-web + backend-api + postgres logs"
	@echo "  local-smoke-test          Start the full local stack, verify health, and stop it"
	@echo "  local-db-reset            Recreate the local Postgres volume and seed baseline data"

bootstrap: install-tools check-tools install-dev-tools
	@echo "Bootstrap completed."

sync-agent-skills:
	@if [[ -f ../platform-blueprint-specs/scripts/sync-common-skills.sh ]]; then \
		bash ../platform-blueprint-specs/scripts/sync-common-skills.sh --repo-root "$$(pwd)"; \
	else \
		echo "Shared skill sync script not found at ../platform-blueprint-specs/scripts/sync-common-skills.sh" >&2; \
		echo "Keep platform-blueprint-specs as a sibling checkout to use make sync-agent-skills in this workspace." >&2; \
		exit 1; \
	fi

sync-agent-skills-check:
	@if [[ -f ../platform-blueprint-specs/scripts/sync-common-skills.sh ]]; then \
		bash ../platform-blueprint-specs/scripts/sync-common-skills.sh --check --repo-root "$$(pwd)"; \
	else \
		echo "Shared skill sync script not found at ../platform-blueprint-specs/scripts/sync-common-skills.sh" >&2; \
		echo "Keep platform-blueprint-specs as a sibling checkout to use make sync-agent-skills-check in this workspace." >&2; \
		exit 1; \
	fi

doctor: sync-agent-skills
	@if [[ -f ../platform-blueprint-specs/scripts/windows-tooling-doctor.ps1 ]]; then \
		powershell -ExecutionPolicy Bypass -File ../platform-blueprint-specs/scripts/windows-tooling-doctor.ps1; \
	else \
		echo "Shared doctor script not found at ../platform-blueprint-specs/scripts/windows-tooling-doctor.ps1" >&2; \
		echo "Keep platform-blueprint-specs as a sibling checkout to use make doctor in this workspace." >&2; \
		exit 1; \
	fi

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
	python -m pre_commit install --hook-type pre-commit --hook-type pre-push

precommit-run:
	python -m pre_commit run --all-files --show-diff-on-failure

lint: repo-lint

format: repo-format

format-check: repo-format-check

repo-lint:
	python scripts/terraform-static-analysis.py

repo-format:
	terraform fmt -recursive

repo-format-check:
	terraform fmt -check -recursive

repo-policy-check:
	python scripts/terraform-policy-check.py

terraform-init:
	@access_token="$${GOOGLE_OAUTH_ACCESS_TOKEN:-}"; \
	if [[ -z "$$access_token" ]] && command -v gcloud.cmd >/dev/null 2>&1; then \
		access_token="$$(gcloud.cmd auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	elif [[ -z "$$access_token" ]] && command -v gcloud >/dev/null 2>&1; then \
		access_token="$$(gcloud auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	fi; \
	if [[ -n "$$access_token" ]]; then \
		export GOOGLE_OAUTH_ACCESS_TOKEN="$$access_token"; \
	fi; \
	for dir in $(TERRAFORM_VALIDATE_DIRS); do \
		echo "Initializing $$dir"; \
		terraform -chdir=$$dir init -backend=false -reconfigure -input=false >/dev/null; \
	done

terraform-validate: terraform-init
	@for dir in $(TERRAFORM_VALIDATE_DIRS); do \
		echo "Validating $$dir"; \
		terraform -chdir=$$dir validate; \
	done

terraform-plan:
	@if [[ -z "$(ENV)" ]]; then \
		echo "ENV is required. Use ENV=rc or ENV=prod." >&2; \
		exit 1; \
	fi
	@access_token="$${GOOGLE_OAUTH_ACCESS_TOKEN:-}"; \
	if [[ -z "$$access_token" ]] && command -v gcloud.cmd >/dev/null 2>&1; then \
		access_token="$$(gcloud.cmd auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	elif [[ -z "$$access_token" ]] && command -v gcloud >/dev/null 2>&1; then \
		access_token="$$(gcloud auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	fi; \
	if [[ -n "$$access_token" ]]; then \
		export GOOGLE_OAUTH_ACCESS_TOKEN="$$access_token"; \
	fi; \
	terraform -chdir=environments/$(ENV) init -input=false; \
	terraform -chdir=environments/$(ENV) plan -input=false -lock-timeout=5m

terraform-apply:
	@if [[ -z "$(ENV)" ]]; then \
		echo "ENV is required. Use ENV=rc or ENV=prod." >&2; \
		exit 1; \
	fi
	@access_token="$${GOOGLE_OAUTH_ACCESS_TOKEN:-}"; \
	if [[ -z "$$access_token" ]] && command -v gcloud.cmd >/dev/null 2>&1; then \
		access_token="$$(gcloud.cmd auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	elif [[ -z "$$access_token" ]] && command -v gcloud >/dev/null 2>&1; then \
		access_token="$$(gcloud auth print-access-token 2>/dev/null | tr -d '\r\n' || true)"; \
	fi; \
	if [[ -n "$$access_token" ]]; then \
		export GOOGLE_OAUTH_ACCESS_TOKEN="$$access_token"; \
	fi; \
	terraform -chdir=environments/$(ENV) init -input=false; \
	terraform -chdir=environments/$(ENV) apply -lock-timeout=5m

local-frontend-support-up:
	$(DOCKER_COMPOSE_ALL_PROFILES) up -d $(DOCKER_BUILD_FLAG) --remove-orphans postgres backend-api

local-api-support-up:
	$(DOCKER_COMPOSE_ALL_PROFILES) up -d $(DOCKER_BUILD_FLAG) --remove-orphans postgres frontend-web

local-full-up:
	$(DOCKER_COMPOSE_ALL_PROFILES) up -d --build --remove-orphans postgres frontend-web backend-api

local-down:
	$(DOCKER_COMPOSE_ALL_PROFILES) down --remove-orphans

local-ps:
	$(DOCKER_COMPOSE_ALL_PROFILES) ps

local-frontend-support-logs:
	$(DOCKER_COMPOSE_ALL_PROFILES) logs -f postgres backend-api

local-api-support-logs:
	$(DOCKER_COMPOSE_ALL_PROFILES) logs -f postgres frontend-web

local-full-logs:
	$(DOCKER_COMPOSE_ALL_PROFILES) logs -f postgres frontend-web backend-api

local-smoke-test:
	powershell -ExecutionPolicy Bypass -File scripts/local-smoke-test.ps1

local-db-reset:
	$(DOCKER_COMPOSE_ALL_PROFILES) down --remove-orphans --volumes
	$(DOCKER_COMPOSE_ALL_PROFILES) up -d --build --wait --remove-orphans postgres
