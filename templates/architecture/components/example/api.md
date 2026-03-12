# API: Example

> Document all interfaces this service exposes or consumes.
> Adapt the sections below to your service type — REST, gRPC, GraphQL,
> CLI, message queue, etc. Delete sections that don't apply.
> This file helps agents understand the contract when
> integrating with or modifying this service.

## Authentication / Access Control

<!-- How callers authenticate or gain access.

- Bearer token (JWT) in Authorization header
- API key via X-API-Key header
- IAM roles (for internal service-to-service)
- N/A (public / no auth)
-->

## Endpoints / Interfaces

<!-- Adapt to your interface type.

REST API:
| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | /api/auth/login | Authenticate user | None |
| GET | /api/users/:id | Get user by ID | Bearer |

gRPC:
| Service | Method | Request | Response |
|---------|--------|---------|----------|
| UserService | GetUser | UserId | UserProfile |
| OrderService | Create | OrderRequest | OrderResponse |

CLI:
| Command | Flags | Purpose |
|---------|-------|---------|
| build | --target, --env | Build project |
| deploy | --stage, --region | Deploy to environment |

Message queue:
| Topic/Queue | Direction | Schema | Purpose |
|-------------|-----------|--------|---------|
| orders.created | Consumes | OrderEvent | Process new orders |
| email.send | Publishes | EmailRequest | Trigger email delivery |
-->

## Key Interface Details

<!-- Request/response schemas for important interfaces.

### POST /api/auth/login

Request:
```json
{ "email": "string", "password": "string" }
```

Response (200):
```json
{ "token": "string", "user": { "id": "string", "email": "string" } }
```

### OrderEvent (message queue)

```json
{ "orderId": "string", "userId": "string", "items": [...], "total": 0.00 }
```
-->

## Events / Signals

<!-- Events, signals, or side effects this service produces or reacts to.

| Event | Direction | Payload | Purpose |
|-------|-----------|---------|---------|
| user.created | Publishes | { userId, email } | New user registered |
| order.completed | Consumes | { orderId, userId } | Trigger post-order flow |
-->
