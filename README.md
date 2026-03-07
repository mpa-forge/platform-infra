# platform-infra

Infrastructure-as-code repository for the platform blueprint.

## Structure
- `modules/`: reusable Terraform modules
- `environments/`: environment-specific Terraform roots
- `docs/`: infrastructure-specific documentation
- `scripts/`: local utility and developer scripts

## Toolchain
- GNU Make (or a compatible `make` implementation) and a bash-compatible shell
- Terraform `1.14.5`
- Version pin source: `.tool-versions` and `versions.tf`

## Setup
Before running bootstrap:
- Required: GNU Make (or a compatible `make` implementation) and a bash-compatible shell
- Recommended: `mise` or `asdf` for automatic tool installation from `.tool-versions`
- Fallback: manually install the pinned tool versions listed above

Run the bootstrap command from the repository root:
- Make: `make bootstrap`

Bootstrap validates the pinned Terraform CLI version.
If `mise` or `asdf` is available, the script will use it to install the pinned toolchain automatically.

## Lint and Format
- Install git hooks: `make precommit-install`
- Run all pre-commit checks manually: `make precommit-run`
- Run repo lint checks: `make lint`
- Formatting is deferred for the infra repo in the Phase 1 baseline

## Run
No Terraform roots are implemented yet.
Infrastructure planning and apply workflows will be added in Phase 5.

The repo does own the centralized Phase 1 local development stack:

- `make local-frontend-support-up` starts `postgres` + `backend-api`
- `make local-api-support-up` starts `postgres` + `frontend-web`
- `make local-full-up` starts `frontend-web` + `backend-api` + `postgres`
- `make local-smoke-test` starts the full stack, verifies health, and stops it
- `make local-down` stops the stack

See `docs/local-development-stack.md` for the local development model and port map.

## Test
No automated validation commands are configured yet.
Formatting, validation, and policy checks will be introduced incrementally in later tasks.
