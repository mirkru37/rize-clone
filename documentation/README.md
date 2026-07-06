# Rize-Clone Documentation

Rize-Clone is an automatic time tracker: the macOS app records app/window activity via native APIs, the iOS app combines on-device Screen Time stats with approximate synced usage and manual/focus sessions, and a Go backend stores, syncs, and aggregates everything across devices.

These documents are the **source of truth** for all contracts. Code must conform to them; any change to a schema, API, or sync behavior updates the corresponding document in the same cycle.

## How to read these docs

New contributors should read in this order: [[system-overview]] → [[database-schema]] → [[api-reference]] → [[sync-protocol]] → the architecture doc for your app → [[security]].

## Map of content

### Overview

- [[system-overview]] — product summary, system context diagram, tech stack per project with justifications, key architectural decisions

### Per-app architecture

- [[architecture-desktop]] — macOS menu-bar client: tracking pipeline, state machine, offline store, permissions
- [[architecture-mobile]] — iOS client: the three-tier hybrid Screen Time model, extensions, entitlements
- [[architecture-backend]] — Go service: layering, ingestion pipeline, aggregation, middleware, operations

### Contracts

- [[api-reference]] — versioning, error format, full route table, worked examples, rate limiting
- [[sync-protocol]] — push/pull design, idempotency, conflict resolution (LWW), cursors, edge cases

### Data & security

- [[database-schema]] — ER diagram, table-by-table schema, TimescaleDB hypertable and continuous aggregates
- [[security]] — authentication and token model, transport and at-rest encryption, privacy, RBAC, rate limits, GDPR, security checklist

### Operations

- [[observability]] — error and performance tracking: Sentry across all projects, integration and privacy rules
- [[deployment]] — environments, promotion pipeline, GCP deployment design, GitHub secrets/vars, free-tier constraints

## Conventions

- File names are kebab-case; wiki links use bare file names without `.md` (`[[database-schema]]`), optionally with display text (`[[database-schema|DB schema]]`).
- All diagrams are Mermaid fenced code blocks.
- Unresolved design details are marked with `> [!note] Open question` callouts — resolve them via a Linear ticket, never silently in code.
- Source-of-truth boundaries: schema changes land in [[database-schema]] first; endpoint changes in [[api-reference]]; sync semantics in [[sync-protocol]]. Architecture docs describe how each app fulfills those contracts.
