# Architecture Principles

> These rules are enforced during plan validation and review. New specs MUST comply.
> Violations cause review findings. Update these rules as the architecture evolves.

## Single Source of Truth

<!-- Every piece of logic, configuration, and shared functionality must have exactly ONE
     canonical location. Before creating anything new, check existing services and libraries.

Examples:
- Business logic MUST NOT be duplicated across services
- Shared logic lives in dedicated libraries under libs/ — reuse, don't reimplement
- Configuration is centralized — no scattered config files per service
- If a library or service already does X, new code MUST import it
-->

## Service Boundaries

<!-- Each service/app owns its domain and exposes a clear public API.
     Internal details are private.

Examples:
- Services communicate via defined APIs or events — never direct database access
- Each service owns its data store exclusively
- No cross-service database queries
- Frontend apps access backend only through API services
-->

## Dependency Direction

<!-- Dependencies flow in one direction. No circular dependencies.

Examples:
- Apps → Services → Libraries (never reverse)
- Libraries depend on abstractions, not concrete service implementations
- Cross-service communication goes through events or APIs, not direct imports
- Shared libraries have zero dependencies on services or apps
-->

## API Contracts

<!-- Examples:
- All APIs require authentication
- Public endpoints must be rate-limited
- API versioning is mandatory
- Errors follow a standardized format
-->

## Data Ownership

<!-- Examples:
- Each service owns its data store
- No direct cross-service database queries
- Shared data goes through events or APIs
- Data migrations are owned by the service that owns the schema
-->

## Reusability

<!-- Before building anything new, check:
1. Does a library in libs/ already do this?
2. Does an existing service expose this capability?
3. Should this be a new shared library instead of service-specific code?

Examples:
- New features must check libs/ before creating anything new
- Common patterns (validation, error handling, logging) use shared libraries
- If 2+ services need the same logic, extract to a library
-->

## Security

<!-- Examples:
- All user input must be validated at the boundary
- Secrets must never be hardcoded
- Inter-service communication must be authenticated
-->

## Testing

<!-- Examples:
- Every public API must have integration tests
- Service logic must have unit tests
- E2E tests cover critical user flows
-->
