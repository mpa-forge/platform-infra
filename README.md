# platform-infra

Infrastructure-as-code repository for the platform blueprint.

## Structure
- `modules/`: reusable Terraform modules
- `environments/`: environment-specific Terraform roots
- `docs/`: infrastructure-specific documentation
- `scripts/`: local utility and developer scripts

## Toolchain
- Terraform `1.14.5`
- Version pin source: `.tool-versions` and `versions.tf`

## Setup
Run one of the following bootstrap commands from the repository root:
- PowerShell: `./scripts/bootstrap.ps1`
- POSIX shell: `./scripts/bootstrap.sh`

Bootstrap validates the pinned Terraform CLI version.
If `mise` or `asdf` is available, the script will use it to install the pinned toolchain automatically.

## Run
No Terraform roots are implemented yet.
Infrastructure planning and apply workflows will be added in Phase 5.

## Test
No automated validation commands are configured yet.
Formatting, validation, and policy checks will be introduced in later tasks.
