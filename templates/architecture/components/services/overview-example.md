# Service: Example

> Replace "Example" with your service name. Name this file `overview-<service-name>.md`.
> This file should be self-contained — an agent reading ONLY this file
> should understand the service well enough to work with it.

## Purpose

<!-- What does this service do? 2-3 sentences. -->

## Ownership

<!-- Team or person responsible for this service. -->

## Tech Stack

<!-- Service-specific technology choices (language, framework, database, etc.) -->

## API Surface

<!-- Key endpoints or interfaces this service exposes.

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /api/auth/login | Authenticate user |
| POST | /api/auth/refresh | Refresh access token |
| GET | /api/auth/me | Get current user |
-->

<!-- Events published or consumed:

| Event | Direction | Purpose |
|-------|-----------|---------|
| user.created | Publishes | New user registered |
| order.completed | Consumes | Trigger post-order flow |
-->

## Data Model

<!-- Core entities and their relationships. Database type. -->

## Dependencies

### Internal
<!-- Other services or libraries this service depends on.

- **shared-utils** (lib) — validation, error formatting
- **auth-service** — token validation via REST
-->

### External
<!-- Third-party APIs, databases, or services.

- PostgreSQL 15 (primary data store)
- Redis (session cache)
- Stripe API (payment processing)
-->

## Key Decisions

<!-- Service-specific architecture decisions, or links to ADRs.

- Uses event sourcing for audit trail (see ADR-003)
- Chose JWT over session tokens for stateless auth
-->
