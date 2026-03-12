# Modules: Example

> List the internal modules or bounded contexts within this component.
> Each module should have a clear responsibility boundary.
> This file helps agents understand the internal structure when
> making changes that touch specific areas.

## Module: Core Logic

<!-- Responsibility, key source paths, internal dependencies.

- **Responsibility:** Main business logic for this component
- **Key paths:** `src/core/`
- **Dependencies:** Database layer, config
- **Key types:** Order, OrderItem, OrderStatus
-->

## Module: Data Access

<!-- Responsibility, key source paths, internal dependencies.

- **Responsibility:** Database queries, migrations, data mapping
- **Key paths:** `src/data/`, `migrations/`
- **Dependencies:** Database driver, ORM
- **Key types:** Repository interfaces, query builders
-->

## Module: Integration

<!-- Responsibility, key source paths, internal dependencies.

- **Responsibility:** Communication with external systems and other services
- **Key paths:** `src/integrations/`
- **Dependencies:** HTTP client, message queue, SDKs
- **Key types:** Client wrappers, event handlers
-->
