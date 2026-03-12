# Component: Example

> Replace "Example" with your component name. Rename this folder to match.
> This file is the entry point — an agent reading ONLY this file
> should understand the component well enough to work with it.
>
> Add detail files alongside this file as needed:
> - `modules.md` — internal module/package breakdown
> - `api.md` — detailed interfaces (REST, gRPC, CLI, events, etc.)
> - `ui.md` — user-facing entry points (pages, screens, commands)

## Purpose
<!-- What does this component do? 2-3 sentences. -->

## Ownership
<!-- Team or person responsible. -->

## Tech Stack
<!-- Language, framework, runtime, database, etc. -->

## Interfaces
<!-- High-level interfaces this component exposes. See api.md for detailed documentation.

Examples for different component types:

REST API:
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /api/auth/login | Authenticate user |
| GET | /api/users/:id | Get user by ID |

CLI:
| Command | Purpose |
|---------|---------|
| build --target prod | Production build |
| migrate --run | Run pending migrations |

Message queue:
| Channel | Direction | Purpose |
|---------|-----------|---------|
| orders.created | Consumes | Process new orders |
| notifications.send | Publishes | Trigger notifications |

gRPC:
| Service | Method | Purpose |
|---------|--------|---------|
| UserService | GetUser | Retrieve user profile |
| UserService | UpdateUser | Modify user data |

Library exports:
| Export | Purpose |
|--------|---------|
| `validate(schema, data)` | Validate input against a schema |
| `sanitize(input)` | Sanitize user input |
-->

## User-Facing Entry Points
<!-- Skip this section for back-end-only services and libraries.
     See ui.md for detailed breakdown.

Web:  / → Dashboard, /settings → Settings
Mobile:  HomeScreen → Main feed, ProfileScreen → User profile
CLI:  init → Set up project, build → Compile sources
-->

## Data Model
<!-- Core entities and storage. Skip for libraries and UI-only apps.
- Orders (PostgreSQL) — order lifecycle, line items
- Sessions (Redis) — active user sessions
-->

## Dependencies

### Internal
<!-- Other components this depends on.
- **shared-utils** (library) — validation, formatting
- **auth** (service) — token validation
-->

### External
<!-- Third-party services, databases, APIs.
- PostgreSQL 15 (primary data store)
- Redis (caching)
- AWS S3 (file storage)
-->

## Consumers
<!-- Who uses this component? Useful for libraries and shared services.
- dashboard (app) — user management features
- billing (service) — auth token validation
-->

## Key Decisions
<!-- Architecture decisions relevant to this component.
- Uses event sourcing for audit trail (see ADR-003)
- Must remain framework-agnostic (no framework deps)
-->
