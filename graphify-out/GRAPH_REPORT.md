# Graph Report - .  (2026-07-06)

## Corpus Check
- Corpus is ~27,089 words - fits in a single context window. You may not need a graph.

## Summary
- 158 nodes · 262 edges · 22 communities (17 shown, 5 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 31 edges (avg confidence: 0.88)
- Token cost: 182,403 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Documentation Suite & Agent Workflow|Documentation Suite & Agent Workflow]]
- [[_COMMUNITY_Sync & Data Architecture Concepts|Sync & Data Architecture Concepts]]
- [[_COMMUNITY_Client Repo Conventions (Swift)|Client Repo Conventions (Swift)]]
- [[_COMMUNITY_Backend API Skeleton (Go)|Backend API Skeleton (Go)]]
- [[_COMMUNITY_SwiftUI App Shells|SwiftUI App Shells]]
- [[_COMMUNITY_Security & Token Model|Security & Token Model]]
- [[_COMMUNITY_Swift Test Placeholders|Swift Test Placeholders]]
- [[_COMMUNITY_AppKit Menu-Bar Shell|AppKit Menu-Bar Shell]]
- [[_COMMUNITY_Master Repo Governance & Docs Site|Master Repo Governance & Docs Site]]
- [[_COMMUNITY_Backend Conventions & CI|Backend Conventions & CI]]
- [[_COMMUNITY_Backend Docker Compose Stack|Backend Docker Compose Stack]]
- [[_COMMUNITY_Desktop View Model|Desktop View Model]]
- [[_COMMUNITY_Post-Commit CI Hook|Post-Commit CI Hook]]
- [[_COMMUNITY_Mermaid Check Script|Mermaid Check Script]]
- [[_COMMUNITY_Wiki-Link Check Script|Wiki-Link Check Script]]
- [[_COMMUNITY_GDPR Deletion Lifecycle|GDPR Deletion Lifecycle]]
- [[_COMMUNITY_Backend Release Pipeline|Backend Release Pipeline]]

## God Nodes (most connected - your core abstractions)
1. `API Reference` - 20 edges
2. `Sync Protocol` - 20 edges
3. `Security Specification` - 17 edges
4. `Database Schema` - 16 edges
5. `Documentation Map of Content` - 15 edges
6. `Mobile Architecture` - 13 edges
7. `Backend Architecture` - 12 edges
8. `MkDocs Site Configuration` - 11 edges
9. `Desktop Architecture` - 11 edges
10. `System Overview` - 10 edges

## Surprising Connections (you probably didn't know these)
- `document-writer Agent Definition` --semantically_similar_to--> `Documentation Map of Content`  [INFERRED] [semantically similar]
  .claude/agents/document-writer.md → documentation/README.md
- `Desktop Release Workflow (unsigned .app on v* tags)` --semantically_similar_to--> `Mobile Release Workflow (unsigned simulator .app, RIZ-25)`  [INFERRED] [semantically similar]
  rize-desktop/.github/workflows/release.yml → rize-mobile/.github/workflows/release.yml
- `Offline-First SQLite Outbox with Immutable Events` --semantically_similar_to--> `Tier B: DeviceActivityMonitor Threshold Events (Approximate)`  [INFERRED] [semantically similar]
  rize-desktop/CLAUDE.md → rize-mobile/CLAUDE.md
- `Developer ID + Notarization Distribution (No App Sandbox)` --semantically_similar_to--> `family-controls Entitlement Approval (RIZ-20)`  [INFERRED] [semantically similar]
  rize-desktop/README.md → rize-mobile/README.md
- `docs-site GitHub Workflow (MkDocs build + Pages deploy)` --references--> `MkDocs Site Configuration`  [INFERRED]
  .github/workflows/docs-site.yml → mkdocs.yml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Offline-First Sync Pipeline (client outbox to hypertable)** — documentation_architecture_desktop_sync_client, documentation_sync_protocol_push_endpoint, documentation_sync_protocol_pull_endpoint, documentation_architecture_backend_ingestion_pipeline, documentation_database_schema_activity_events_hypertable, documentation_system_overview_uuidv7_idempotency [EXTRACTED 1.00]
- **Orchestrator Delegation Workflow (brief, implement, review, document)** — claude_orchestrator_role, agents_code_writer, agents_code_reviewer, agents_document_writer [EXTRACTED 1.00]
- **MkDocs Documentation Site Toolchain** — mkdocs, requirements_docs, workflows_docs_site, documentation_readme [EXTRACTED 1.00]
- **Backend Local Compose Stack (db → migrate → api startup chain)** — rize_backend_docker_compose_db, rize_backend_docker_compose_migrate, rize_backend_docker_compose_api [EXTRACTED 1.00]
- **Documentation-as-Source-of-Truth Contract Governance** — rize_backend_claude_guidelines, rize_desktop_claude_guidelines, rize_mobile_claude_guidelines, documentation_api_reference, documentation_sync_protocol, documentation_database_schema [EXTRACTED 1.00]
- **Work Deferred on family-controls Entitlement (RIZ-20)** — rize_mobile_readme_family_controls_entitlement, rize_mobile_project_xcodegen_spec, workflows_release_rize_mobile_release, rize_mobile_claude_tier_a_report_extension, rize_mobile_claude_tier_b_monitor_extension [EXTRACTED 1.00]

## Communities (22 total, 5 thin omitted)

### Community 0 - "Documentation Suite & Agent Workflow"
Cohesion: 0.41
Nodes (21): code-reviewer Agent Definition, code-writer Agent Definition, document-writer Agent Definition, Rize-Clone Master Repo CLAUDE.md, Containerization Requirement, documentation/ Is the Source of Truth, API Reference, Backend Architecture (+13 more)

### Community 1 - "Sync & Data Architecture Concepts"
Cohesion: 0.11
Nodes (21): Forward-Only Migration Policy (golang-migrate), Ingestion Pipeline (validate, app catalog resolution, category resolution, idempotent upsert), Desktop Event Store (SQLite via GRDB, outbox), Desktop Tracking State Machine (active/idle/locked/sleeping), Desktop Sync Client (60s / 500-event flush), Desktop Tracking Engine, App Group Container group.com.rizeclone.shared, DeviceActivityMonitor Extension (Tier B thresholds) (+13 more)

### Community 2 - "Client Repo Conventions (Swift)"
Cohesion: 0.14
Nodes (19): Rize-Clone Git Flow (one ticket → one branch → one PR), rize-desktop Engineering Guidelines (CLAUDE.md), Offline-First SQLite Outbox with Immutable Events, Tracking Engine Isolation from UI, RizeDesktop XcodeGen Project Spec (macOS 14+, LSUIElement, hardened runtime), Developer ID + Notarization Distribution (No App Sandbox), Desktop SwiftLint Config, rize-mobile Engineering Guidelines (CLAUDE.md) (+11 more)

### Community 3 - "Backend API Skeleton (Go)"
Cohesion: 0.20
Nodes (16): healthzHandler(), main(), newRouter(), readyzHandler(), requestLogger(), run(), TestHealthz(), TestReadyzWithoutDatabase() (+8 more)

### Community 4 - "SwiftUI App Shells"
Cohesion: 0.18
Nodes (9): App, RizeDesktopApp, RizeMobileApp, Scene, Scene, SwiftUI, View, DashboardView (+1 more)

### Community 5 - "Security & Token Model"
Cohesion: 0.18
Nodes (11): Backend Middleware Stack (Request ID, Logging, Recoverer, CORS, Rate limit, Auth, RBAC), Modular Monolith Service Shape, DeviceActivityReport Extension (Tier A), refresh_tokens Table (Rotation Families), Sentry for Error Tracking and Performance, Certificate Pinning Deliberately Deferred, Rate Limiting (token bucket, per-IP auth / per-user sync), RBAC (user/admin, user_id scoping) (+3 more)

### Community 6 - "Swift Test Placeholders"
Cohesion: 0.25
Nodes (5): RizeDesktopTests, RizeMobile, DashboardViewTests, XCTest, XCTestCase

### Community 7 - "AppKit Menu-Bar Shell"
Cohesion: 0.25
Nodes (6): AppDelegate, AppKit, Notification, NSApplicationDelegate, NSObject, NSStatusItem

### Community 8 - "Master Repo Governance & Docs Site"
Cohesion: 0.40
Nodes (5): Git Flow: One Ticket, One Branch, One PR, Orchestrator Role, Rize-Clone README, Docs Site Python Requirements, docs-site GitHub Workflow (MkDocs build + Pages deploy)

### Community 9 - "Backend Conventions & CI"
Cohesion: 0.40
Nodes (5): rize-backend Engineering Guidelines (CLAUDE.md), Handlers → Services → Repositories Layering, Per-User Query Scoping (Tenant Isolation), Backend golangci-lint Config, Backend CI Workflow (lint, test, vuln, docker)

### Community 10 - "Backend Docker Compose Stack"
Cohesion: 0.70
Nodes (5): Compose Service: api (multi-stage Go build), Compose Service: db (timescale/timescaledb pg16), Compose Service: migrate (migrate/migrate one-shot), Backend Docker Compose Stack, TimescaleDB Hypertable + Continuous Aggregates for activity_events

### Community 11 - "Desktop View Model"
Cohesion: 0.50
Nodes (3): Foundation, Observation, MenuContentViewModel

## Knowledge Gaps
- **28 isolated node(s):** `Request`, `AppKit`, `NSStatusItem`, `Notification`, `Scene` (+23 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `API Reference` connect `Documentation Suite & Agent Workflow` to `Sync & Data Architecture Concepts`, `Client Repo Conventions (Swift)`, `Backend Conventions & CI`?**
  _High betweenness centrality (0.102) - this node is a cross-community bridge._
- **Why does `Security Specification` connect `Documentation Suite & Agent Workflow` to `Client Repo Conventions (Swift)`, `Security & Token Model`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `Sentry for Error Tracking and Performance` connect `Security & Token Model` to `Documentation Suite & Agent Workflow`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Sync Protocol` (e.g. with `Offline-First SQLite Outbox with Immutable Events` and `Tier B: DeviceActivityMonitor Threshold Events (Approximate)`) actually correct?**
  _`Sync Protocol` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Documentation Map of Content` (e.g. with `document-writer Agent Definition` and `docs-ci GitHub Workflow (markdownlint, wiki-links, mermaid)`) actually correct?**
  _`Documentation Map of Content` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Request`, `AppKit`, `NSStatusItem` to the rest of the system?**
  _35 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Sync & Data Architecture Concepts` be split into smaller, more focused modules?**
  _Cohesion score 0.11428571428571428 - nodes in this community are weakly interconnected._