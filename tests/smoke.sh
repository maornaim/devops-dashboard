#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  echo "ERROR: .env file was not found in $PROJECT_DIR" >&2
  exit 1
fi

set -a
source .env
set +a

: "${DB_USER:?ERROR: DB_USER is missing from .env}"
: "${DB_NAME:?ERROR: DB_NAME is missing from .env}"

BASE_URL="${BASE_URL:-http://localhost}"
EMAIL="smoke-$(date +%s)-$$@example.com"

cleanup_user() {
  docker compose exec -T database \
    psql \
    --username "$DB_USER" \
    --dbname "$DB_NAME" \
    --set ON_ERROR_STOP=1 \
    --command "DELETE FROM users WHERE email = '$EMAIL';" \
    > /dev/null
}

finish() {
  test_exit_code=$?
  trap - EXIT

  echo "Cleaning up smoke-test user..."
  if cleanup_user; then
    echo "Cleanup passed."
  else
    echo "ERROR: Smoke-test user cleanup failed." >&2
    test_exit_code=1
  fi

  if [[ $test_exit_code -eq 0 ]]; then
    echo "Smoke test passed."
  else
    echo "Smoke test failed." >&2
  fi

  exit "$test_exit_code"
}

trap finish EXIT

echo "Checking liveness..."
curl --fail --silent --show-error "$BASE_URL/health" > /dev/null

echo "Checking readiness..."
curl --fail --silent --show-error "$BASE_URL/ready" > /dev/null

echo "Checking database connection..."
curl --fail --silent --show-error "$BASE_URL/test-db" > /dev/null

echo "Creating smoke-test user..."
curl --fail --silent --show-error \
  --request POST \
  --header "Content-Type: application/json" \
  --data "{\"username\":\"Smoke Test\",\"email\":\"$EMAIL\"}" \
  "$BASE_URL/users" \
  > /dev/null

echo "Checking that the user was saved..."
curl --fail --silent --show-error "$BASE_URL/users" \
  | grep --fixed-strings --quiet "$EMAIL"
