# Django Backend CI/CD Pipeline

![CI](https://github.com/HariniMuruganantham/django-backend-cicd-pipeline/actions/workflows/backend-ci.yml/badge.svg)
[![Coverage](https://codecov.io/gh/HariniMuruganantham/django-backend-cicd-pipeline/branch/main/graph/badge.svg)](https://codecov.io/gh/HariniMuruganantham/django-backend-cicd-pipeline)

A production-style CI/CD pipeline for a Django backend, built with GitHub Actions. Every push and pull request to `main` automatically runs code quality checks, tests, security scans, and a Docker image build — with each stage gating the next.

---

## Pipeline Overview

```
push / pull_request to main
          │
          ▼
┌─────────────────────┐
│  Job 1: run-tests   │  Code quality (flake8, black, isort, mypy)
│                     │  pytest + coverage (≥50% required)
│                     │  Upload report to Codecov
└────────┬────────────┘
         │ needs: run-tests
         ▼
┌─────────────────────┐
│  Job 2: trivy-scan  │  Trivy filesystem scan
│                     │  Fails on unfixed CRITICAL/HIGH CVEs
└────────┬────────────┘
         │ needs: trivy-scan
         ▼
┌─────────────────────┐
│  Job 3: docker-scan │  docker build
│                     │  Trivy image scan
│                     │  Fails on unfixed CRITICAL/HIGH CVEs
└─────────────────────┘
```

Each job only runs if the previous one passes. A failure in tests stops the security scan; a failure in the filesystem scan stops the Docker build.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Django 5.2.11 | Web framework |
| pytest + pytest-django | Test runner |
| pytest-cov / Codecov | Coverage reporting |
| flake8 | Linting |
| black | Code formatting |
| isort | Import ordering |
| mypy | Static type checking |
| Docker | Containerisation |
| Trivy | CVE scanning (filesystem + image) |
| GitHub Actions | CI/CD orchestration |

---

## Security Fixes Applied

The pipeline will catch and block these — they were present in earlier versions of this project and serve as a concrete example of what the scanner detects:

| CVE | Severity | Description | Fixed in |
|---|---|---|---|
| CVE-2025-64459 | CRITICAL | Django SQL injection | 5.2.8 |
| CVE-2025-64458 | HIGH | DoS on Windows | 5.2.8 |
| CVE-2026-1207 | HIGH | SQL injection via RasterField | 5.2.11 |
| CVE-2026-1287 | HIGH | SQL injection via column aliases | 5.2.11 |
| CVE-2026-1312 | HIGH | SQL injection via QuerySet.order_by() | 5.2.11 |

All resolved by pinning `Django==5.2.11` in `requirements.txt`.

---

## Repository Structure

```
django-backend-cicd-pipeline/
├── .github/
│   └── workflows/
│       └── backend-ci.yml    # CI/CD pipeline definition
├── cidemo/                   # Django project package
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── core/                     # Django app
│   └── __init__.py
├── .flake8                   # Linter config
├── .gitignore
├── Dockerfile
├── manage.py
├── mypy.ini                  # Type checker config
├── pyproject.toml            # black + isort config
├── pytest.ini                # Test runner config
├── requirements.txt
└── README.md
```

---

## Running Locally

### Prerequisites

- Python 3.12
- Docker (for the image build step)

### 1. Clone and set up

```bash
git clone https://github.com/HariniMuruganantham/django-backend-cicd-pipeline.git
cd django-backend-cicd-pipeline
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install flake8 black isort mypy pytest pytest-django pytest-cov
```

### 2. Run tests (uses in-memory SQLite automatically — no Postgres needed)

```bash
pytest
```

### 3. Run code quality checks

```bash
flake8 .
black --check .
isort --check-only .
mypy .
```

### 4. Build and run with Docker

```bash
docker build -t django-backend-ci .
docker run -p 8000:8000 django-backend-ci
```

### 5. Local dev without Postgres

```bash
USE_SQLITE_FOR_LOCAL=1 python manage.py migrate
USE_SQLITE_FOR_LOCAL=1 python manage.py runserver
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `SECRET_KEY` | insecure dev default | Django secret key — **always override in production** |
| `DEBUG` | `True` | Set to `False` in production |
| `ALLOWED_HOSTS` | `*` | Comma-separated list of allowed hostnames |
| `POSTGRES_DB` | `cidemo_db` | Database name |
| `POSTGRES_USER` | `postgres` | Database user |
| `POSTGRES_PASSWORD` | *(empty)* | Database password — required for Postgres |
| `POSTGRES_HOST` | `localhost` | Database host |
| `POSTGRES_PORT` | `5432` | Database port |
| `USE_SQLITE_FOR_LOCAL` | unset | Set to `1` to use file-based SQLite locally |
| `USE_SQLITE_FOR_TESTS` | unset | Set to `1` to force SQLite in tests |

---

## GitHub Actions Setup

Two repository secrets are required:

| Secret | Where to get it |
|---|---|
| `CODECOV_TOKEN` | https://codecov.io — link your repo and copy the token |

No other secrets are needed for CI — the test job uses in-memory SQLite and requires no database credentials.

---

## Design Decisions

**No Postgres service in CI** — `settings.py` automatically switches to in-memory SQLite when pytest is running. This makes the test job faster, simpler, and free of infrastructure dependencies. Postgres is only needed when testing database-specific behaviour (migrations, raw SQL), which this project doesn't have yet.

**Jobs are chained with `needs:`** — tests must pass before Trivy scans the filesystem; the filesystem scan must pass before the image is built and scanned. This means a dependency vulnerability blocks the Docker build entirely rather than just producing a warning.

**Trivy pinned to `@0.68.0`** — using `@master` would expose the pipeline to breaking changes and supply-chain risk. The version is pinned but recent enough to have up-to-date CVE definitions.

**Non-root Docker user** — the Dockerfile creates a dedicated `appuser` and switches to it before running the application. Running as root inside a container is a common misconfiguration that Trivy will flag.