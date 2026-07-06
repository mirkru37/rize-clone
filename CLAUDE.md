# Rize-Clone — Master Repo

Automatic time tracker for **macOS + iOS** (Rize.io clone) with a dedicated Go backend. This is the master repo; the three sub-projects are git submodules, each with its own README and CLAUDE.md.

## Project map

| Path | Purpose | Stack |
|---|---|---|
| `rize-desktop/` | macOS menu-bar client, automatic tracking via native APIs | Swift 5.10+, SwiftUI + AppKit, GRDB/SQLite |
| `rize-mobile/` | iOS client, hybrid Screen Time tracking + manual/focus sessions | Swift, SwiftUI, DeviceActivity/FamilyControls |
| `rize-backend/` | Auth, ingestion, sync, reporting API | Go 1.23+, Chi, PostgreSQL 16 + TimescaleDB |
| `documentation/` | Architecture documentation suite — **the source of truth** | Markdown, Mermaid, Obsidian `[[wiki-links]]` |

Start with `documentation/README.md` for the map of content.

## Golden rules

1. **`documentation/` is the source of truth.** Code must conform to the contracts in `documentation/database-schema.md`, `documentation/api-reference.md`, and `documentation/sync-protocol.md`. Any change to a contract (schema, API, sync protocol) requires updating the corresponding doc in the same cycle — dispatch the document-writer for it.
2. **Submodule git semantics.** Never run git write operations against a submodule from the master repo root — `cd` into the submodule first. After a submodule PR merges, commit the pointer bump in the master repo.
3. **Every task maps to a Linear issue.** No untracked work.
4. **Containerization.** Every containerizable project must provide a `Dockerfile` and be runnable end-to-end with `docker compose` (currently `rize-backend`: api + TimescaleDB + migrations). `rize-desktop` and `rize-mobile` are exempt — macOS/iOS GUI apps cannot run in Linux containers.

## Git flow

One Linear ticket → one branch → one PR, all named after the ticket:

NEVER work in main branch, ALWAYS branch off a Linear ticket or create new branch from main.

ALWAYS create branch from fresh main branch. Ex:
```
  git fetch
  git checkout -b feat/RIZ-<n>-<short-slug> origin/main
```

- **Branch**: `feat/RIZ-<n>-<short-slug>` (use `fix/`, `docs/`, `chore/` prefixes as appropriate), e.g. `feat/RIZ-42-implement-user-model`.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`) referencing `RIZ-<n>` in the scope or body.
- **PR**: title `[RIZ-<n>] <summary>`, body links the Linear issue, states what changed and how it was tested. One atomic task per PR. PRs merge into the submodule's `main`, then a pointer-bump commit lands in the master repo.
- **Stacked (nested) PRs — allowed to unblock dependent tasks.** When Task B depends on Task A whose PR is not yet merged: branch B off Task A's branch (`git fetch && git checkout -b feat/RIZ-<b>-<slug> origin/feat/RIZ-<a>-<slug>`) and open B's PR with base = Task A's branch (`gh pr create --base feat/RIZ-<a>-<slug>`), noting the dependency in the PR body. Rules: B's PR diff must contain only B's changes; never merge B before A; after A merges, retarget B to `main` (GitHub retargets automatically when A's branch is deleted on merge), rebase B on fresh `main`, and re-run CI before merging B. If A's branch changes after review feedback, rebase B onto it promptly.
- **Linear status flow**: `In Progress` when work is dispatched → `In Review` when the PR opens → `Done` at merge.

## Linear

- Team: **RizeClone** (key `RIZ`, id `79594331-1aed-49b0-b265-9782de6b2702`), via the Linear MCP.
- **Projects = milestones/epics** (e.g. "Users Implementation"). **Issues = short atomic tasks** (e.g. "Implement User model"). Epic context lives with the orchestrator, which writes full briefs when delegating.
- Example future epics: "Backend Skeleton & Auth", "Desktop Tracking MVP", "Sync & Ingestion v1".

## Subagents (`.claude/agents/`)

**The main (default) chat session is the orchestrator** (contract: `.claude/agents/orchestrator.md`). It never writes code, reviews, or docs inline — every delegated task must name its agent per the mandatory mapping: code changes (incl. CI/config/fixes) → `code-writer`; every PR review and re-review → `code-reviewer`; documentation → `document-writer`.

| Agent | Model / effort | Responsibility |
|---|---|---|
| `orchestrator` | — | Operating contract for the main session: defines work, delegates, reviews, triages. Not a dispatchable subagent. |
| `code-writer` | sonnet / medium | Implements exactly one atomic task from a full brief; opens exactly one PR. |
| `code-reviewer` | opus / high | Severity-graded review report (HIGH/MEDIUM/LOW) on a PR; never edits code. |
| `document-writer` | sonnet / medium | Expands a brief containing all logic details into extensive docs; must not alter the given details. |
