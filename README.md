# DevOps Dashboard

A small multi-container project for learning and demonstrating core DevOps practices with Docker Compose.

## Architecture

```text
Client -> Nginx :80 -> Gunicorn :5000 -> Flask -> PostgreSQL :5432 -> Docker volume
```

- **Nginx** is the public entry point and reverse proxy.
- **Gunicorn** runs and manages two Flask worker processes.
- **Flask** provides the web page, API endpoints, validation, health checks, and error handling.
- **PostgreSQL** stores users in the `dashboard` database.
- **Docker Compose** manages service networking, health checks, startup order, and persistent storage.

## Features

- Separate liveness and readiness endpoints.
- Health checks for Flask and PostgreSQL.
- Reliable startup with `service_healthy` dependencies.
- Persistent PostgreSQL data using a named volume.
- Request validation and safe HTTP error responses.
- Local configuration through `.env`.
- Automated end-to-end smoke testing with cleanup.
- Continuous integration with GitHub Actions.

## Run Locally

Create a local environment file from the example:

```bash
cp .env.example .env
```

Replace the `change_me` values, then start the stack:

```bash
docker compose up -d --build
```

Check service status:

```bash
docker compose ps
```

## Smoke Test

The Bash smoke test verifies the complete request path through Nginx, Gunicorn,
Flask, and PostgreSQL. It checks health and readiness, creates a temporary user,
confirms that the user was stored, and removes the test user during cleanup.

Run it from Git Bash while the stack is running:

```bash
bash tests/smoke.sh
```

A successful run ends with `Smoke test passed` and exit code `0`.

## CI Pipeline

The GitHub Actions workflow runs for pushes and pull requests targeting `main`.
Each run uses a fresh Ubuntu runner and performs these steps:

```text
Checkout repository
-> Create test environment
-> Validate Docker Compose
-> Build and start services
-> Run smoke test
-> Show Docker logs on failure
-> Clean up containers and test volume
```

The protected `main` branch requires the `Build and smoke test` check to pass
before a pull request can be merged.

## API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/` | Dashboard page |
| `GET` | `/health` | Flask liveness check |
| `GET` | `/ready` | Flask and PostgreSQL readiness check |
| `GET` | `/test-db` | Database connection test |
| `GET` | `/users` | List users |
| `POST` | `/users` | Create a user |

## Logs

```bash
docker compose logs app
docker compose logs database
docker compose logs nginx
```
