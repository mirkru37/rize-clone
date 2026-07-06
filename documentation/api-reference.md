# API Reference

This document describes the Rize-Clone backend HTTP API: conventions, route groups, worked examples, and rate limiting behavior. For the broader system context, see [[system-overview]] and [[architecture-backend]]. For the semantics of the sync-specific endpoints, see [[sync-protocol]].

## Conventions

All versioned endpoints are served under a common base URL with `/v1` path versioning, e.g. `https://api.rize-clone.example/v1`. The conventions below apply to every route in this document unless explicitly noted otherwise (the unversioned [[#Ops]] endpoints are the only exception).

- **Content type**: all request and response bodies are JSON (`Content-Type: application/json`), except where a route explicitly states otherwise.
- **Errors**: error responses use an RFC 7807-style problem body:

  ```json
  {
    "type": "https://api.rize-clone.example/errors/invalid-credentials",
    "title": "Invalid credentials",
    "status": 401,
    "detail": "The email or password provided is incorrect."
  }
  ```

  `type` is a URI identifying the error category, `title` is a short human-readable summary, `status` mirrors the HTTP status code, and `detail` gives request-specific context.
- **Authentication**: authenticated requests carry `Authorization: Bearer <access-token>`. Access tokens are short-lived; see [[security]] for token lifetime and rotation policy, and the Auth route group below for how tokens are issued and refreshed.
- **Request IDs**: every response echoes a request identifier (used for support/debugging correlation and log tracing). Clients should log this value alongside any error they surface.
- **Pagination**: list endpoints that support pagination use a cursor-based convention: callers pass `limit` (page size) and an opaque `cursor` query parameter. The server returns the page of results plus a cursor for the next page. Cursors are opaque tokens and must not be parsed or constructed by clients. Every list endpoint's response body uses the same envelope:

  ```json
  {
    "data": [ /* page of resources */ ],
    "next_cursor": "opaque-cursor-string",
    "has_more": true
  }
  ```

  `data` is the page of resources for that endpoint (each shaped per that resource's own schema), `next_cursor` is the opaque token to pass as `cursor` on the following request, and `has_more` indicates whether another page is available. This envelope applies to every list endpoint in this document, including the four [[#CRUD groups]] (`GET /v1/projects`, `/v1/tags`, `/v1/categories`, `/v1/focus-sessions`).

> [!note] Open question
> The brief does not specify the exact request ID header/field name (e.g. `X-Request-Id` vs. a body field) or the precise access-token lifetime. These are written here at the level of detail given; confirm exact wire format before implementation.

## Route groups

### Auth

| Method | Path | Description | Auth level |
|---|---|---|---|
| POST | `/v1/auth/register` | Email + password signup | public |
| POST | `/v1/auth/login` | Email + password login | public |
| POST | `/v1/auth/apple` | Sign in with Apple (identity token exchange) | public |
| POST | `/v1/auth/refresh` | Rotate refresh token, issue new access token | public |
| POST | `/v1/auth/logout` | Revoke current refresh token | authenticated |
| POST | `/v1/auth/password/forgot` | Request a password reset | public |
| POST | `/v1/auth/password/reset` | Complete a password reset | public |

The register, login, and Apple sign-in routes are public (no bearer token required) since they are how a client obtains its first token pair. `refresh` rotates the refresh token and mints a new access token, and is likewise called without an existing valid access token (it uses the refresh token itself as its credential). `logout` requires an authenticated session and revokes the refresh token backing it, ending that session. See [[security]] for token rotation and revocation details, and [[architecture-desktop]] / [[architecture-mobile]] for how each client persists and refreshes tokens.

`register`, `login`, and `refresh` all return the same `authResponse` shape: `access_token` (signed JWT), `refresh_token` (opaque, `rt_`-prefixed), `token_type` (`"Bearer"`), `expires_in` (access token lifetime in seconds), `user`, and `device`. `register` and `login` both require a `device` object in the request body (`platform`, `name`, `model`, `os_version`, `app_version`, plus an optional `id` — omitted by the client when registering a brand-new device, populated by the server in the echoed response so the client can reuse it on later calls). `refresh`'s request body carries `refresh_token` and an optional `device` object with the same id semantics. `logout`'s request body carries only `refresh_token` and responds `204 No Content`.

Known error types surfaced by the auth handlers, each following the RFC 7807-style body from [[#Conventions]] with `type` set to `https://api.rize-clone.example/errors/<slug>`:

| Slug | Status | Meaning |
|---|---|---|
| `invalid-request-body` | 400 | Request body is missing, malformed, or not valid JSON |
| `validation-error` | 400 | Request body parsed but failed field-level validation — e.g. `register`/`login` reject a `password` shorter than 8 characters or longer than 1024 bytes (the upper bound is enforced before hashing, to bound argon2id's per-request cost; see [[security]]) |
| `email-already-registered` | 409 | `register` was called with an email that already has an account |
| `invalid-credentials` | 401 | `login` was called with an incorrect email/password combination |
| `invalid-refresh-token` | 401 | `refresh` or `logout` was called with a refresh token that is unknown, expired, or already revoked |
| `refresh-token-reuse-detected` | 401 | `refresh` was called with a token that was already rotated; the entire token family for the device has been revoked (see [[security]]) |
| `device-not-found` | 404 | A `device.id` was supplied that does not resolve to a device owned by the authenticating user |
| `user-not-found` | 404 | The user backing a token or credential no longer exists |
| `unauthenticated` | 401 | `logout` was called without a valid `Authorization: Bearer` access token |
| `internal-error` | 500 | Unexpected server-side failure |

### Users

| Method | Path | Description | Auth level |
|---|---|---|---|
| GET | `/v1/users/me` | Fetch current user profile | authenticated |
| PATCH | `/v1/users/me` | Update current user profile | authenticated |
| DELETE | `/v1/users/me` | GDPR deletion request (7-day grace period) | authenticated |
| POST | `/v1/users/me/export` | Request a data export (JSON dump) | authenticated |

`DELETE /v1/users/me` does not delete data immediately; it starts a 7-day grace period during which the deletion can presumably be cancelled, after which the account and associated data are purged. See [[security]] for the deletion and retention policy. `POST /v1/users/me/export` triggers generation of a full JSON data export for the requesting user.

### Devices

| Method | Path | Description | Auth level |
|---|---|---|---|
| GET | `/v1/devices` | List devices registered to the current user | authenticated |
| PATCH | `/v1/devices/{id}` | Rename a device | authenticated |
| DELETE | `/v1/devices/{id}` | Revoke a device and its refresh tokens | authenticated |

Revoking a device via `DELETE /v1/devices/{id}` invalidates every refresh token issued to that device, forcing it to re-authenticate. This is the primary mechanism for a user to remotely sign out a lost or compromised device. See [[architecture-desktop]] and [[architecture-mobile]] for device registration flow during onboarding.

### Sync

| Method | Path | Description | Auth level |
|---|---|---|---|
| POST | `/v1/sync/events` | Batched idempotent event ingest (batch ≤ 500) | authenticated |
| GET | `/v1/sync/changes?cursor=&limit=` | Cursor-based pull of upserts and tombstones | authenticated |

`POST /v1/sync/events` accepts a batch of up to 500 events per request and is idempotent — resubmitting the same event (by its idempotency key) does not create duplicates. `GET /v1/sync/changes` is the pull side of sync: it returns a page of upserts and tombstones since the given cursor, using the same cursor-and-limit pagination convention described above. Full semantics for idempotency, conflict resolution, and tombstone handling are defined in [[sync-protocol]]; this document only covers the transport shape.

### Activities & reports

| Method | Path | Description | Auth level |
|---|---|---|---|
| GET | `/v1/activities` | Raw events by time range and filters (app, category, project, device, precision) | authenticated |
| GET | `/v1/reports/summary` | Aggregate summary report | authenticated |
| GET | `/v1/reports/daily` | Daily breakdown report | authenticated |
| GET | `/v1/reports/categories` | Time-by-category report | authenticated |
| GET | `/v1/reports/apps` | Time-by-app report | authenticated |
| GET | `/v1/reports/projects` | Time-by-project report | authenticated |
| GET | `/v1/reports/timeline` | Chronological timeline report | authenticated |

`GET /v1/activities` returns raw tracked events, filterable by time range, app, category, project, device, and precision (precision reflecting how granular the underlying tracked activity is). The `/v1/reports/*` endpoints return derived aggregates over the same underlying activity data, each sliced along a different dimension (summary, daily, category, app, project, timeline). See [[architecture-backend]] for how raw activity events are aggregated into these reports.

### CRUD groups

The following resources expose the standard list / create / get / update / delete operations:

| Method | Path pattern | Description |
|---|---|---|
| GET | `/v1/projects` | List projects |
| POST | `/v1/projects` | Create project |
| GET | `/v1/projects/{id}` | Get project |
| PATCH | `/v1/projects/{id}` | Update project |
| DELETE | `/v1/projects/{id}` | Delete project |
| GET / POST / GET / PATCH / DELETE | `/v1/tags` , `/v1/tags/{id}` | Same pattern for tags |
| GET / POST / GET / PATCH / DELETE | `/v1/categories` , `/v1/categories/{id}` | Same pattern for categories |
| GET / POST / GET / PATCH / DELETE | `/v1/focus-sessions` , `/v1/focus-sessions/{id}` | Same pattern for focus sessions |

All CRUD group endpoints require an authenticated request (auth level: authenticated). List endpoints (`GET /v1/projects`, `/v1/tags`, `/v1/categories`, `/v1/focus-sessions`) follow the cursor-based pagination convention described in [[#Conventions]].

### Admin

| Method | Path | Description | Auth level |
|---|---|---|---|
| GET | `/v1/admin/users` | List users | admin |
| PATCH | `/v1/admin/users/{id}` | Update a user | admin |

Admin routes are gated by role-based access control and require the caller's role to be `admin`. See [[security]] for the RBAC model.

### Ops

| Method | Path | Description | Auth level |
|---|---|---|---|
| GET | `/healthz` | Liveness check | public |
| GET | `/readyz` | Readiness check | public |
| GET | `/metrics` | Prometheus metrics | public |

These operational endpoints are unversioned (no `/v1` prefix) and sit outside the JSON/error-body conventions described above — `/metrics` in particular returns the Prometheus text exposition format rather than JSON. See [[architecture-backend]] for how these are wired into deployment and monitoring.

## Worked examples

### 1. POST /v1/auth/login

`device` is required on both `register` and `login`. When a client submits a new device that does not yet have a server-assigned id, it omits `device.id` in the request; the server assigns one and echoes the full device object — including the new `device.id` — back in the response. On subsequent calls the client passes that same `device.id` back so the server matches/updates the existing device row rather than creating a new one.

Request:

```json
POST /v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "correct-horse-battery-staple",
  "device": {
    "platform": "macos",
    "name": "Roman's MacBook Pro",
    "model": "MacBookPro18,3",
    "os_version": "14.5",
    "app_version": "1.2.0"
  }
}
```

Response (200 OK):

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "rt_9f8c1e2a4b3d4c5e8f7a6b5c4d3e2f1a",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": "usr_01HZX3K4Q9T7V8W9Y0Z1A2B3C4",
    "email": "user@example.com",
    "role": "user"
  },
  "device": {
    "id": "dev_01J2K3M4N5P6Q7R8S9T0U1V2W3",
    "platform": "macos",
    "name": "Roman's MacBook Pro",
    "model": "MacBookPro18,3",
    "os_version": "14.5",
    "app_version": "1.2.0"
  }
}
```

Error example (401 Unauthorized) using the RFC 7807-style body:

```json
{
  "type": "https://api.rize-clone.example/errors/invalid-credentials",
  "title": "Invalid credentials",
  "status": 401,
  "detail": "The email or password provided is incorrect."
}
```

`POST /v1/auth/register` follows the identical request/response shape (`device` required, `authResponse` returned), except it returns `201 Created` and can additionally fail with `email-already-registered` (409) instead of `invalid-credentials`.

### 2. POST /v1/auth/refresh

`device` is optional on refresh. Omit it to simply rotate the refresh token and mint a new access token without touching device state; supply it (with or without `device.id`) to update an existing device or register a new one as part of the same call, using the same `device.id` semantics described above.

Request (without device):

```json
POST /v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "rt_9f8c1e2a4b3d4c5e8f7a6b5c4d3e2f1a"
}
```

Response (200 OK):

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "rt_1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": "usr_01HZX3K4Q9T7V8W9Y0Z1A2B3C4",
    "email": "user@example.com",
    "role": "user"
  },
  "device": {
    "id": "dev_01J2K3M4N5P6Q7R8S9T0U1V2W3",
    "platform": "macos",
    "name": "Roman's MacBook Pro",
    "model": "MacBookPro18,3",
    "os_version": "14.5",
    "app_version": "1.2.0"
  }
}
```

Error example (401 Unauthorized) on reuse of an already-rotated refresh token:

```json
{
  "type": "https://api.rize-clone.example/errors/refresh-token-reuse-detected",
  "title": "Refresh token reuse detected",
  "status": 401,
  "detail": "This refresh token has already been rotated; the token family has been revoked."
}
```

### 3. POST /v1/auth/logout

Requires an authenticated request (`Authorization: Bearer <access-token>`).

Request:

```json
POST /v1/auth/logout
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "refresh_token": "rt_1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d"
}
```

Response: `204 No Content` (empty body).

### 4. POST /v1/sync/events

Request (batch of three events, idempotent by `event_id`):

```json
POST /v1/sync/events
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "events": [
    { "event_id": "evt_001", "type": "app_focus", "app": "com.apple.dt.Xcode", "started_at": "2026-07-06T09:00:00Z", "ended_at": "2026-07-06T09:15:00Z" },
    { "event_id": "evt_002", "type": "app_focus", "app": "com.tinyspeck.slackmacgap", "started_at": "2026-07-06T09:15:00Z", "ended_at": "2026-07-06T09:20:00Z" },
    { "event_id": "evt_003", "type": "app_focus", "app": "", "started_at": "2026-07-06T09:20:00Z", "ended_at": "2026-07-06T09:10:00Z" }
  ]
}
```

Response (200 OK) — partial success, with a per-item result of `applied`, `duplicate`, or `invalid`:

```json
{
  "results": [
    { "event_id": "evt_001", "status": "applied" },
    { "event_id": "evt_002", "status": "duplicate" },
    { "event_id": "evt_003", "status": "invalid", "detail": "ended_at precedes started_at" }
  ]
}
```

Here `evt_001` was newly ingested, `evt_002` had already been ingested previously (idempotent replay, no-op), and `evt_003` failed validation but did not prevent the other two items in the batch from being applied. See [[sync-protocol]] for the full idempotency and conflict-resolution semantics that govern how per-item outcomes are determined.

### 5. GET /v1/reports/daily

Request:

```
GET /v1/reports/daily?date=2026-07-06
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

Response (200 OK):

```json
{
  "date": "2026-07-06",
  "total_tracked_seconds": 27300,
  "categories": [
    { "category": "Development", "seconds": 18000 },
    { "category": "Communication", "seconds": 5400 },
    { "category": "Uncategorized", "seconds": 3900 }
  ]
}
```

## Rate limiting

Requests that exceed the applicable rate limit receive a `429 Too Many Requests` response with a `Retry-After` header indicating (in seconds) how long the client should wait before retrying. Rate-limited responses use the standard RFC 7807-style error body described in [[#Conventions]].

Responses also carry rate-limit headers so clients can proactively back off before hitting the limit (current usage, remaining quota, and reset time).

Limits are scoped differently depending on the route group:

- **Auth endpoints** (`/v1/auth/*`) are rate-limited per-IP, to mitigate credential-stuffing and brute-force attempts against `register`, `login`, and `password/forgot` in particular.
- **Sync and reports endpoints** (`/v1/sync/*`, `/v1/reports/*`) are rate-limited per-user, reflecting expected per-client sync cadence and report query volume.

The specific numeric limits and windows for each scope are defined in [[security]] rather than here.

> [!note] Open question
> The brief does not specify the exact names of the rate-limit response headers (e.g. `X-RateLimit-Limit` / `X-RateLimit-Remaining` / `X-RateLimit-Reset`). Written here generically pending confirmation.

For `POST /v1/sync/events`, clients that need to retry after a 429 (or after any transient failure) should rely on the idempotency guarantee described in [[sync-protocol]] rather than mutating or deduplicating the batch client-side — resubmitting the same batch is safe.

## Related

- [[system-overview]]
- [[architecture-backend]]
- [[architecture-desktop]]
- [[architecture-mobile]]
- [[sync-protocol]]
- [[security]]
