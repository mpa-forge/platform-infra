# Observability Secret Delivery

## Purpose

Define the Phase 3 secret-delivery contract for Grafana OTLP credentials before
Phase 5 introduces deployable Terraform roots in this repository.

## Current Status

`platform-infra` does not yet contain the Cloud Run or GKE Terraform roots that
will eventually own workload definitions. This document locks the delivery
contract now so the application/runtime repos can consume one stable secret and
environment model.

## Cloud Run Baseline Path

Cloud Run services should receive Grafana OTLP settings through the following
runtime inputs:

- plain environment variables:
  - `OTEL_MODE=direct_otlp`
  - `OBS_TELEMETRY_PROFILE=<balanced|cost|debug>`
  - `OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-prod-us-east-3.grafana.net/otlp`
  - `GRAFANA_CLOUD_INSTANCE_ID=1546554`
- secret environment variable from GSM:
  - `GRAFANA_OTLP_INGEST_TOKEN`

The `backend-api` runtime and shared `backendobs` package compose the final
OTLP Basic auth header at startup from `GRAFANA_CLOUD_INSTANCE_ID` and
`GRAFANA_OTLP_INGEST_TOKEN`. Cloud Run should not inject
`OTEL_EXPORTER_OTLP_HEADERS` directly.

See `docs/placeholders/cloud-run/backend-api-observability-env.tf.example` for
an implementation-oriented Terraform snippet that can be moved into the Phase 5
Cloud Run module/root once that structure exists.

## GKE Alternative Path

The GKE path will use the same runtime contract with different secret delivery:

- plain config:
  - `OTEL_MODE=collector_gateway`
  - `OBS_TELEMETRY_PROFILE=<balanced|cost|debug>`
  - `OTEL_EXPORTER_OTLP_ENDPOINT=<collector or alloy OTLP receiver URL>`
  - `GRAFANA_CLOUD_INSTANCE_ID=1546554`
- secret delivery:
  - `GRAFANA_OTLP_INGEST_TOKEN` synced from GSM into Kubernetes via
    External Secrets Operator (ESO)

See `docs/placeholders/gke/backend-api-otlp-external-secret.yaml` for the
placeholder ExternalSecret manifest.
See `docs/placeholders/gke/backend-api-observability-env.yaml` for the
workload-facing environment contract and
`docs/placeholders/gke/backend-api-collector-gateway.yaml` for the collector
receivers/processors/exporters baseline.

These files are intentionally illustrative and are not applied from this repo
yet.

## RC Secret Mapping

- GCP project: `mpa-forge-bp-rc`
- GSM secret: `grafana-otlp-ingest-token-rc`
- consumer env var: `GRAFANA_OTLP_INGEST_TOKEN`

## Profile and Collector Mapping

For the future GKE path, `platform-infra` owns the deployment-time inputs that
let the shared runtime and collector stay aligned:

- `OBS_TELEMETRY_PROFILE` remains the service-facing control.
- `TRACE_SAMPLE_PERCENT` is a collector-owned derived input that should map to:
  - `balanced`: `25` in `rc`, `5` in `prod`
  - `cost`: `10` in `rc`, `2` in `prod`
  - `debug`: `100`
- the collector keeps force-sample rules for:
  - trace error status
  - spans slower than `1s`
  - spans tagged with `platform.observability.force_sample.reason`

The shared runtime remains the source of truth for application-facing mode and
profile selection; the collector path adds downstream processing without
changing service instrumentation or secret shapes.

## Rollout Boundary

Current Phase 3 scope in this repo:

- document the shared Grafana token-ingredient contract
- provide illustrative Cloud Run and GKE placeholder artifacts
- make the collector path concrete enough for sibling repos and planning docs
  to target one stable contract

Deferred to Phase 5/6:

- deployable Terraform roots and modules
- Helm or Kubernetes release wiring that applies the collector config
- live GKE validation and rollout automation

## Deferred Items

- Actual Cloud Run Terraform wiring remains deferred until Phase 5 introduces
  deployable Terraform roots/modules in `platform-infra`.
- Actual collector deployment and live GKE-path validation remain deferred until
  the Phase 5/6 runtime-path roots exist.
- Prod GSM secret delivery remains deferred until prod activation.
- Worker secret delivery is deferred to Phase 9.
