# Design: Deployment Presets Over Environment Boundaries

## Overview

The change introduces a two-layer model:

- environment roots keep project boundaries, remote state, naming, and
  environment-specific defaults
- a shared stack module chooses runtime topology from a preset catalog

This preserves one root per environment while removing duplicated assembly code.

## Preset Model

`modules/stack` owns a local preset catalog keyed by `deployment_preset`.
Each preset declares:

- frontend runtime kind
- backend runtime kind
- database runtime kind
- observability mode
- derived module activation flags

Current presets:

- `single-vps`
- `cloudrun-cloudsql`
- `cloudrun-cdn-cloudsql`
- `gke-cloudsql`

`deployment_enabled` remains a separate input so committed roots can declare
their intended topology without creating infrastructure by default.

## Runtime Composition

`modules/stack` is responsible for:

- deriving module activation from the selected preset
- composing the shared secret catalog
- wiring Cloud Run, GKE, or VPS runtime contracts
- building one normalized output contract regardless of runtime choice

The runtime-specific modules remain implementation-focused:

- `cloudrun_api` manages the Cloud Run runtime
- `gke` manages optional cluster and workload-identity secret access metadata
- `vps_stack` manages a single VM, public IP, firewall, and runtime metadata
- `secrets` provides reusable secret catalog metadata for Cloud Run and GKE

## Output Contract

The stack module exports:

- `project_boundaries`
- `deployment_contract`
- `service_contracts`
- `network_contracts`

`deployment_contract` stabilizes the cross-preset interface with:

- `active_preset`
- `frontend_contract`
- `backend_contract`
- `database_contract`
- `operational_contract`

This lets downstream tooling read topology details without branching on root
internals.

## Module Extensions

Existing modules were extended to support the preset architecture:

- `cloudrun_api`: explicit least-privilege secret IAM selection and secret IAM
  output contract
- `gke`: workload identity principals and ESO mapping outputs
- `secrets`: environment-scoped runtime secret catalog plus Cloud Run and ESO
  views

These additions let `modules/stack` treat Cloud Run and GKE as composable
runtime paths while keeping the underlying implementation GCP-native.
