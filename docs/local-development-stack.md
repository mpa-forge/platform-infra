# Local Development Stack

`platform-infra` owns the canonical Docker Compose setup for Phase 1 local development.

## Supported modes

- `frontend` native development:
  - run `frontend-web` natively on the host
  - Compose runs `postgres` and `backend-api`
- `api` native development:
  - run `backend-api` natively on the host
  - Compose runs `postgres` and `frontend-web`

`backend-worker` and `platform-ai-workers` are intentionally excluded from the default local stack in Phase 1.

## Compose file

- path: `local/compose.yml`
- project name: `platform-blueprint-local`

## Centralized commands

From `platform-infra`:

- `make local-frontend-support-up`
- `make local-api-support-up`
- `make local-down`
- `make local-ps`
- `make local-frontend-support-logs`
- `make local-api-support-logs`

Application repos call these targets through thin repo-local wrappers so the compose definition stays centralized.

## Ports

- `frontend-web` container: `http://localhost:3000`
- `backend-api` container: `http://localhost:8080`
- `postgres`: `localhost:5432`

## Data

- Postgres uses the named Docker volume `postgres-data`.
- Phase 1 only provisions an empty database instance.
- Schema/bootstrap seed content is introduced later in `P1-T09`.

## Runtime assumptions

- The containerized frontend is built with `VITE_API_BASE_URL=http://localhost:8080` so the browser running on the host can talk to a native or containerized API on the host port.
- The containerized API uses `postgres` as the database host inside the compose network.
- Native service reload is manual: rerun the repo-local `make run` command after code changes.
