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
- `make local-full-up`
- `make local-smoke-test`
- `make local-down`
- `make local-ps`
- `make local-frontend-support-logs`
- `make local-api-support-logs`
- `make local-full-logs`

Application repos call these targets through thin repo-local wrappers so the compose definition stays centralized.

## Ports

- `frontend-web` container: `http://localhost:3000`
- `backend-api` container: `http://localhost:8080`
- `postgres`: `localhost:5432`

## Full stack mode

If you want all three services containerized at once:

- `make local-full-up`
- `make local-full-logs`
- `make local-smoke-test`
- `make local-down`

This mode is useful for validating the combined baseline without running either app natively on the host.

## Smoke testing

The centralized smoke scripts live in `scripts/`:

- `scripts/local-smoke-test.ps1`
- `scripts/local-smoke-test.sh`

They:

- bring up the full local stack
- wait for Postgres to become healthy
- verify `http://localhost:3000/healthz`
- verify `http://localhost:8080/healthz`
- tear the stack down unless explicitly told to keep it running

## Data

- Postgres uses the named Docker volume `postgres-data`.
- Postgres loads initialization SQL from `local/postgres-init/`.
- Phase 1 baseline schema:
  - table: `bootstrap_records`
- Phase 1 baseline seed rows:
  - `stack_version=phase-1`
  - `seed_source=platform-infra/local/postgres-init`
- To recreate the baseline from scratch:
  - `make local-db-reset`
- Init scripts only run on a fresh Postgres volume, which is why the reset target removes the named volume first.

## Runtime assumptions

- The containerized frontend is built with `VITE_API_BASE_URL=http://localhost:8080` so the browser running on the host can talk to a native or containerized API on the host port.
- The containerized API uses `postgres` as the database host inside the compose network.
- Native service reload is manual: rerun the repo-local `make run` command after code changes.
