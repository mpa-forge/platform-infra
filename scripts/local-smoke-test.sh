#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="${repo_root}/local/compose.yml"
keep_running="false"

if [[ "${1:-}" == "--keep-running" ]]; then
  keep_running="true"
fi

compose() {
  docker compose -f "${compose_file}" --profile frontend-support --profile api-support "$@"
}

wait_for_http_ok() {
  local name="$1"
  local url="$2"
  local expected_body="${3:-}"

  for _ in $(seq 1 30); do
    if body="$(curl -fsS "${url}")"; then
      body="$(printf '%s' "${body}" | tr -d '\r\n')"
      if [[ -z "${expected_body}" || "${body}" == "${expected_body}" ]]; then
        echo "${name} check passed"
        return 0
      fi
    fi
    sleep 2
  done

  echo "${name} check failed for ${url}" >&2
  return 1
}

cleanup() {
  if [[ "${keep_running}" != "true" ]]; then
    compose down --remove-orphans >/dev/null
  fi
}

trap cleanup EXIT

compose down --remove-orphans >/dev/null
compose up -d --build --wait --remove-orphans postgres frontend-web backend-api >/dev/null

echo "postgres health check passed"
wait_for_http_ok "frontend" "http://localhost:3000/healthz"
wait_for_http_ok "backend-api" "http://localhost:8080/healthz" "ok"

echo "Local smoke test passed"
