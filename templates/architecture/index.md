# Architecture Index

> **Agent instructions:** This is the routing table. Scan the user's task for keywords,
> match against entries below, and load ONLY the docs relevant to the current task.
> Do NOT load everything — selective loading keeps context focused and efficient.
>
> Keep keywords accurate and comprehensive. The more precise the keywords,
> the better the architecture context matching.
>
> Each component lives in its own folder under `components/` (e.g.,
> `components/auth/` or `components/payments/payment-api/`).
> Start with `overview.md` for high-level context. Load detail files
> (`modules.md`, `api.md`, `ui.md`) only when the task requires deeper
> understanding of that component's internals.

<!-- ═══ Organize sections below to match YOUR project ═══

Sections are just headers — name them whatever makes sense:
- By type:   Services | Apps | Libraries | Infrastructure | Scripts
- By domain: Payments | Identity | Shared | Platform
- By team:   Team Alpha | Team Beta | Platform

Path patterns:
- Flat:      components/<name>/overview.md
- Grouped:   components/<domain>/<name>/overview.md

Add a "Type" column to distinguish component kinds within a section.
-->

## Components

<!-- Replace this section with your own — organized by type, domain, or team.

| Name | Type | Purpose | Keywords | Path |
|------|------|---------|----------|------|
| auth | service | Authentication & authorization | login, JWT, OAuth, session | components/auth/overview.md |
| billing | service | Payment processing & subscriptions | payment, invoice, subscription | components/billing/overview.md |
| notifications | worker | Multi-channel notification delivery | email, push, SMS, webhook | components/notifications/overview.md |
| dashboard | app | Admin web interface | admin, dashboard, settings | components/dashboard/overview.md |
| mobile | app | iOS/Android client | mobile, app, push, offline | components/mobile/overview.md |
| shared-utils | library | Common validation, formatting, helpers | validate, format, sanitize | components/shared-utils/overview.md |
-->

<!-- === Example: domain-grouped monorepo ===

## Payments
| Name | Type | Purpose | Keywords | Path |
|------|------|---------|----------|------|
| payment-api | service | Payment REST API | payment, charge, refund | components/payments/payment-api/overview.md |
| payment-worker | worker | Async payment processing | settlement, webhook | components/payments/payment-worker/overview.md |
| payment-dashboard | app | Payment admin UI | payment admin, refunds | components/payments/payment-dashboard/overview.md |

## Identity
| Name | Type | Purpose | Keywords | Path |
|------|------|---------|----------|------|
| auth-service | service | Authentication | login, JWT, OAuth | components/identity/auth-service/overview.md |
| admin-portal | app | Admin tools | admin, users, roles | components/identity/admin-portal/overview.md |
-->

## Integrations

<!-- External system connections.

| Name | Purpose | Keywords | Path |
|------|---------|----------|------|
| stripe | Payment gateway | payment, card, charge, refund | integrations/stripe.md |
| sendgrid | Transactional email | email, template, delivery | integrations/sendgrid.md |
-->

## Decisions

<!-- Architecture Decision Records.

| ID | Title | Status | Path |
|----|-------|--------|------|
| ADR-001 | Example decision | Accepted | decisions/ADR-001-example.md |
-->
