## MODIFIED Requirements

### Requirement: Backend API startup environment contract

The Cloud Run API service SHALL receive the required backend startup
environment variables for the Cloud Run baseline, including application
environment, log level, HTTP port, database host or Cloud SQL socket path,
database name, database user, secret-backed database password, auth issuer,
auth audience, runtime path, direct OTLP mode, telemetry profile, OTLP endpoint,
Grafana instance ID, and Grafana ingest token reference. The environment root
MUST NOT inject a committed full database URL containing database credentials
as the canonical Cloud Run API database contract.

#### Scenario: Environment root composes startup variables

- **WHEN** the `rc` or `prod` root instantiates the Cloud Run API module
- **THEN** the root MUST pass plain and secret-backed environment variables
  matching the backend API startup contract for the selected environment.

#### Scenario: Database password uses Secret Manager

- **WHEN** the Cloud Run API service is enabled with Cloud SQL
- **THEN** `DB_PASSWORD` MUST be injected from Secret Manager and the runtime
  service account MUST be granted secret accessor permission for that password
  secret.

#### Scenario: Grafana token uses Secret Manager

- **WHEN** the Cloud Run API service is enabled
- **THEN** `GRAFANA_OTLP_INGEST_TOKEN` MUST be injected from Secret Manager and
  the runtime service account MUST be granted secret accessor permission for
  that secret.
