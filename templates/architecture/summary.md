# Architecture Summary

> This file is loaded at the start of every run alongside `index.md` and `principles.md`.
> Keep it **compact** — high-level overview only. Individual service, app, and library
> details live in their own docs under `services/`, `apps/`, and `libs/`.
> This file should stay roughly the same size regardless of how many services exist.

## System Purpose

<!-- What does this system do? 2-3 sentences max. -->

## Architecture Style

<!-- e.g., Microservices monorepo, Modular monolith, Serverless, etc. -->

## Tech Stack

<!-- Key technologies used across the system.

| Layer | Technology |
|-------|------------|
| Backend | Node.js, TypeScript |
| Frontend | React, Next.js |
| Database | PostgreSQL, Redis |
| Infrastructure | AWS, Docker, Kubernetes |
| CI/CD | GitHub Actions |
-->

## Cross-Cutting Concerns

<!-- Patterns and strategies that apply across ALL services/apps.

- **Authentication:** JWT-based, centralized via auth service
- **Observability:** Structured logging, distributed tracing via OpenTelemetry
- **Error handling:** Standardized error codes, centralized error types
- **Communication:** REST for sync, event bus for async cross-service
-->

## Major Constraints

<!-- Hard rules that apply system-wide.

- All services must be stateless and horizontally scalable
- PII must be encrypted at rest and in transit
- API response latency budget: <200ms p95
-->
