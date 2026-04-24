# Proposal: Deployment Presets Over Environment Boundaries

## Summary

Add a preset-driven environment assembly layer so `rc` and `prod` remain the
only Terraform roots while runtime topology becomes a selectable input. This
introduces a shared `modules/stack` composition module, a new `single-vps`
runtime path, and a normalized output contract that remains stable across
presets.

## Motivation

The previous root structure mixed environment policy with per-module activation
flags. That made it hard to express reusable topologies such as:

- RC on a single VPS
- prod on Cloud Run + Cloud SQL
- future CDN frontend or GKE variants

Without a preset layer, each topology either required manual toggles or a new
environment root, both of which increase drift and operator error.

## Changes

- add `deployment_preset` and `deployment_enabled` to environment roots
- derive module activation inside a shared `modules/stack` module
- add a `single-vps` preset backed by a new `modules/vps_stack`
- keep `rc` and `prod` as separate roots with different preset defaults
- expose `deployment_contract` plus normalized frontend/backend/database output
  shapes
- extend existing Cloud Run, GKE, and secrets modules so they can participate
  in a shared runtime contract

## Non-Goals

- making the implementation cloud-agnostic in this change
- provisioning managed CDN/static frontend hosting in Terraform
- replacing the existing GCP runtime modules with abstract provider-neutral
  backends
