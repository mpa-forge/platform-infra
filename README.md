# platform-infra

Infrastructure-as-code repository for the platform blueprint.

## Structure
- modules/: reusable Terraform modules
- environments/: environment-specific Terraform roots
- docs/: infrastructure-specific documentation
- scripts/: local utility and developer scripts

## Toolchain
- GNU Make (or a compatible make implementation)
- Terraform 1.14.5
- Version pin source: .tool-versions and ersions.tf

## Setup
Before running bootstrap:
- Required: GNU Make (or a compatible make implementation)
- Recommended: mise or sdf for automatic tool installation from .tool-versions
- Fallback: manually install the pinned tool versions listed above

Run the bootstrap command from the repository root:
- Make: make bootstrap

Bootstrap validates the pinned Terraform CLI version.
If mise or sdf is available, the script will use it to install the pinned toolchain automatically.

## Run
No Terraform roots are implemented yet.
Infrastructure planning and apply workflows will be added in Phase 5.

## Test
No automated validation commands are configured yet.
Formatting, validation, and policy checks will be introduced in later tasks.
