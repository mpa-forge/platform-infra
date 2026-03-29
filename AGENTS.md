# Agent Context

## Local Entry Point

This file is the repo-local entry point for agent context.

## Always Load

Before making changes:

1. Read `README.md`.
2. Read `Makefile` if present.
3. Read `docs/local-development-stack.md` when the task affects local stack orchestration.
4. Read `../platform-blueprint-specs/common/AGENTS.md`.
5. Read `../platform-blueprint-specs/.codex/skills/automated-ai-worker/SKILL.md` when the repo is being changed by an automated AI worker or when following the same autonomous workflow manually.
6. Read `../platform-blueprint-specs/implementation/phases/phase-1-repository-and-local-development-baseline.md`.
7. Read `../platform-blueprint-specs/ops/ephemeral-gke-cluster-lifecycle-requirements.md`.

## Repo Role

- Own Terraform modules and environment roots.
- Own the centralized local development stack orchestration for frontend, API, and Postgres.
- Keep both Cloud Run and GKE paths available, with Cloud Run as the current baseline.

## Relevant Shared Constraints

- Cloud Run is the initial API runtime baseline.
- GKE remains a supported alternative path, but no cluster is created for the initial iteration.
- The local development stack is hybrid and centralized here.
- Terraform environment structure uses separate roots per environment with shared modules.

## Consult Conditionally

- `../platform-blueprint-specs/platform-specification.md` only when the task needs broader cross-platform architecture decisions.

## Typical Validation

- `make lint`
- repo-local compose or smoke commands when stack behavior changes

## Priority of Instructions

Repo-local instructions override shared planning docs.

If local repo docs conflict with a shared planning file, the more specific repo or task instruction wins.
