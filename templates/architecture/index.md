# Architecture Index

> **Agent instructions:** This is the routing table. Scan the user's task for keywords,
> match against entries below, and load ONLY the docs relevant to the current task.
> Do NOT load everything — selective loading keeps context focused and efficient.
>
> Keep keywords accurate and comprehensive. The more precise the keywords,
> the better the architecture context matching.
>
> All component docs live under `components/` — services, apps, and libs are flat
> files named `overview-<name>.md`. Additional per-component docs (API specs, data
> models, etc.) use the pattern `<topic>-<name>.md` in the same directory.

## Services

<!-- Backend microservices and API services.

| Name | Purpose | Keywords | Path |
|------|---------|----------|------|
| auth | Authentication & authorization | login, JWT, OAuth, permissions, session | components/services/overview-auth.md |
| billing | Payment processing & subscriptions | payment, invoice, subscription, pricing | components/services/overview-billing.md |
| notifications | Multi-channel notification delivery | email, push, SMS, alert, webhook | components/services/overview-notifications.md |
-->

## Apps

<!-- Frontend applications, micro-frontends, and client apps.

| Name | Purpose | Keywords | Path |
|------|---------|----------|------|
| dashboard | Admin web interface | admin, dashboard, settings, management | components/apps/overview-dashboard.md |
| storefront | Customer-facing web app | shop, cart, checkout, product, catalog | components/apps/overview-storefront.md |
-->

## Libraries

<!-- Shared packages and reusable libraries.

| Name | Purpose | Keywords | Path |
|------|---------|----------|------|
| shared-utils | Common validation, formatting, helpers | validate, format, sanitize, helpers | components/libs/overview-shared-utils.md |
| ui-components | Shared React component library | button, modal, form, table, component | components/libs/overview-ui-components.md |
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
