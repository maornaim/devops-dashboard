# DevOps Dashboard

A small multi-container project for learning and demonstrating core DevOps practices with Docker Compose.

## Architecture

```text
Client -> Nginx :80 -> Flask :5000 -> PostgreSQL :5432 -> Docker volume
```

- **Nginx** is the public entry point and reverse proxy.
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
