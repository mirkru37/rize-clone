# Rize-Clone

An automatic time tracker for **macOS and iOS** (inspired by Rize.io). The macOS app tracks app/window activity automatically via native APIs; the iOS app combines Apple Screen Time data with manual and focus-session tracking; a dedicated Go backend handles storage, cross-device sync, and user roles.

This is the master repository. The sub-projects are git submodules:

| Submodule | Purpose | Stack |
|---|---|---|
| [`rize-desktop`](rize-desktop/README.md) | macOS menu-bar client with automatic activity tracking | Swift, SwiftUI + AppKit, GRDB/SQLite |
| [`rize-mobile`](rize-mobile/README.md) | iOS client with hybrid Screen Time + manual tracking | Swift, SwiftUI, DeviceActivity/FamilyControls |
| [`rize-backend`](rize-backend/README.md) | Auth, event ingestion, sync, and reporting API | Go, Chi, PostgreSQL + TimescaleDB |

## Documentation

The architecture documentation lives in [`documentation/`](documentation/README.md) and is the **source of truth** for all contracts (database schema, API, sync protocol, security requirements). Start there before touching any code.

## Getting started

Clone with submodules:

```
git clone --recurse-submodules <repo-url>
```

Or initialize submodules after a normal clone:

```
git submodule update --init --recursive
```

Pull latest submodule changes:

```
git submodule update --remote --merge
```

## Development workflow

Work is tracked in Linear (team **RizeClone**, key `RIZ`): projects are milestones/epics, issues are short atomic tasks.

**Git flow — one ticket, one branch, one PR:**

1. Every task has a Linear ticket (`RIZ-<n>`).
2. Create a branch named after the ticket: `feat/RIZ-<n>-<short-slug>` (or `fix/`, `docs/`, `chore/`), e.g. `feat/RIZ-42-implement-user-model`.
3. Commit using Conventional Commits referencing the ticket.
4. Open exactly one PR per ticket, titled `[RIZ-<n>] <summary>`, linking the Linear issue; it must resolve that ticket and nothing else.
5. PRs merge into the submodule's `main`; then the submodule pointer bump is committed in this master repo.
6. Linear status: In Progress → In Review (PR open) → Done (merged).
