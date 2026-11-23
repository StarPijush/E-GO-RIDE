# Stage 0 Go backend implementation report

## Discovery and decisions

- Confirmed: Jhargram, Toto-only, cash-only, phone OTP, nearest-first dispatch, server-authoritative lifecycle, and Supabase. The newest owner instruction selects Go as the backend language and a standalone Go HTTP API. It explicitly supersedes the earlier TypeScript backend direction while retaining Supabase Auth, PostgreSQL, PostGIS, and Realtime.
- Sources reviewed: blueprint index and files 01–22; normative `20-STATE-MACHINE.md`; latest architecture and final audits; repository instructions; existing backend/infrastructure/packages; Flutter and Next.js manifests/docs; driver/admin scaffold state.
- Existing work classification: the PostGIS schema, RLS foundation, canonical contract documentation, and local Supabase configuration from the prior attempt remain reusable. TypeScript backend config/contracts/tests and npm metadata were removed. Existing unrelated modified frontend/docs files were left untouched.
- Open decisions carried forward: D2–D9 and Q-2/Q-8/Q-9/Q-10. D4 fare caps and Q-9 staff permissions do not block this restrictive foundation; neither is implemented as policy.

## Conflicts and implementation choices

- Older data/API/dispatch examples use `open/matched/accepted`; the v2 normative `20-STATE-MACHINE.md` uses `quote_pending/driver_accepted/arriving/in_progress`. The SQL uses the normative request and trip states.
- API 13 has older accept routes and mandatory `cash_amount` completion examples; v2 defines passenger quote acceptance and separates cash declaration. The contract docs preserve the v2 path and mark all business operations planned.
- Blueprint 06 originally places business logic in Supabase Edge Functions, which run TypeScript. The new owner instruction explicitly selects a standalone Go API. This implementation follows that newer choice; the database/Auth platform remains Supabase.
- Supabase legacy HS256 tokens do not expose a public JWKS. The Go verifier uses the configured Supabase Auth `/user` endpoint for those tokens and uses JWKS for asymmetric keys; it never stores a shared JWT secret.

## Implemented files

- Go module and app: `go.mod`, `cmd/api/main.go`, `internal/config`, `internal/server`, `internal/middleware`, `internal/platform/database`, `internal/platform/supabase`, `internal/shared/response`, and `internal/shared/validation`.
- Database: existing Supabase config, seed entry point, PostGIS migration, RLS and pgTAP tests; the migration includes an `e_go_api` non-login group role for non-owner runtime credentials.
- SQLC: `sqlc.yaml`, `sql/queries/health.sql`, and generated code directory (generation status reported below).
- API: `api/openapi.yaml` documents the implemented health/readiness routes and planned API groups.
- Configuration/container: `.env.example`, `Dockerfile`.
- Docs: backend README, architecture, database schema, API contracts, security, local development, and this report.

## Implemented behavior

- `GET /health` reports process liveness; `GET /ready` reports database readiness without exposing connection details.
- Graceful shutdown, JSON structured logs, request body cap, explicit CORS allowlist, request timeouts, safe panic responses, and environment validation are implemented.
- JWT middleware verifies asymmetric ES256/RS256/EdDSA signatures using configured JWKS and validates issuer, audience, expiry, issued-at, authenticated role, and UUID subject. Legacy HS256 is delegated to Supabase Auth `/user` verification. Only the verified subject enters request context.
- pgx pool settings cap connections/timeouts. `WithUserTx` sets the `authenticated` role and transaction-local claims from a verified UUID subject.
- Business APIs, OTP delivery, database workflows, dispatch, tracking, cash operations, admin mutations, and Realtime publication remain unimplemented.

## Database summary

Implemented tables: profiles, passenger profiles, service areas, drivers, vehicles, driver sessions, driver locations, ride requests, booking intents, fare quotes, ride offers, trips, ride event log, cash ledger, idempotency records, outbox events, admin audit events, and support tickets. PostgreSQL checks, foreign keys, partial uniqueness, PostGIS GiST indexes, RLS, explicit grants, transaction-time database role context, and append-only event/ledger/audit triggers are described in `DATABASE_SCHEMA.md`.

## Stage 0 verification and quality gate (2026-11-23)

This is a verification-only gate. No Stage 1 work or passenger/driver frontend edits were made as part of it. Tool discovery used PowerShell `Get-Command`: `go`, `sqlc`, `docker`, `supabase`, and `psql` all returned `MISSING`.

### Tooling installation commands for Windows PowerShell

Run these from an elevated PowerShell where required, then open a new terminal and verify with `go version`, `sqlc version`, `docker version`, `supabase --version`, and `psql --version`.

```powershell
# Go toolchain
winget install --id GoLang.Go --exact

# sqlc 1.31.1 standalone Windows x64 archive
$sqlcZip = Join-Path $env:TEMP 'sqlc_1.31.1_windows_amd64.zip'
$sqlcDir = Join-Path $env:USERPROFILE 'bin\sqlc'
Invoke-WebRequest 'https://downloads.sqlc.dev/sqlc_1.31.1_windows_amd64.zip' -OutFile $sqlcZip
New-Item -ItemType Directory -Force -Path $sqlcDir | Out-Null
Expand-Archive -LiteralPath $sqlcZip -DestinationPath $sqlcDir -Force
$env:Path += ";$sqlcDir"

# Docker Desktop (reboot/WSL2 setup may be required)
winget install --id Docker.DockerDesktop --exact

# Supabase CLI, installed in a temporary npm prefix (Node.js 20+ required)
$supabasePrefix = Join-Path $env:TEMP 'ego-supabase-cli'
npm install --prefix $supabasePrefix supabase
$env:Path += ";$(Join-Path $supabasePrefix 'node_modules\.bin')"

# PostgreSQL client (EDB PostgreSQL installer includes psql)
winget install --id PostgreSQL.PostgreSQL.18 --exact
```

The Go installer is listed by the official Go downloads page; sqlc publishes the Windows archive; Supabase documents npm as a project-scoped CLI installation and requires Node.js 20+; Docker Desktop is the recommended Windows container runtime for Supabase local development. This machine's specific WinGet package IDs may need confirmation with `winget search` if its configured catalog differs.

### Command execution results

Commands were attempted from `backend/`. The actual PowerShell result for each was that the command was not recognized because its executable is absent:

| Command | Result |
| --- | --- |
| `gofmt -w .` | **BLOCKED** — `gofmt` is not recognized. No files were formatted by this command. |
| `go mod tidy` | **BLOCKED** — `go` is not recognized; `go.sum` was not generated. |
| `go vet ./...` | **BLOCKED** — `go` is not recognized. |
| `go test ./...` | **BLOCKED** — `go` is not recognized. |
| `go build -o .\out\api.exe .\cmd\api` | **BLOCKED** — `go` is not recognized. |
| `sqlc generate` | **BLOCKED** — actual output: `sqlc : The term 'sqlc' is not recognized as the name of a cmdlet...`. |
| `supabase start`, `supabase db reset`, and `supabase test db` | **BLOCKED** — each returned `supabase : The term 'supabase' is not recognized...`. |
| `docker version` | **BLOCKED** — actual output: `docker : The term 'docker' is not recognized...`. |
| `psql --version` | **BLOCKED** — actual output: `psql : The term 'psql' is not recognized...`. |

No compile, test, build, migration, or pgTAP pass is claimed. Runtime startup, `/health`, `/ready`, graceful shutdown, config behavior, and database error handling remain dynamically unverified. Existing unit tests cover configuration, health/readiness, safe errors, and JWT conditions, but were not executable here.

After Go is installed, the PowerShell recursive formatting command for this repository is `Get-ChildItem -Recurse -Filter *.go | ForEach-Object { gofmt -w $_.FullName }`; `gofmt -w .` itself does not recursively enumerate Go files.

### JWT security audit

| Check | Result |
| --- | --- |
| Signature verification | **PASS (code inspection only)** — asymmetric tokens go through `jwt.ParseWithClaims` and the configured JWKS key function; legacy HS256 acceptance is delegated to Auth `/user`. Dynamic execution is **BLOCKED**. |
| JWKS endpoint / key selection | **PASS (code inspection only)** — configuration pins the endpoint to the configured Supabase project's JWKS URL; keyfunc is configured with a 5-second HTTP timeout and 10-minute refresh interval. |
| Algorithm restrictions | **PASS (code inspection only)** — only ES256, RS256, and EdDSA pass the asymmetric allowlist; HS256 takes only the Auth `/user` path; all other algorithms are rejected. |
| Issuer, audience, expiration | **PASS (code inspection only)** — parser/validator enforce configured issuer and audience and require expiration. Existing tests include wrong issuer, wrong audience, and expired tokens, but were **NOT RUN**. |
| Subject / role | **PASS (code inspection only)** — requires role `authenticated`, issued-at, and UUID subject before constructing the principal. |
| Incorrect signature | **PASS (test exists, NOT RUN)** — the existing test signs with a different RSA private key and expects rejection. |
| Legacy HS256 | **PASS (test/code inspection only)** — no local shared JWT secret; calls the configured Auth `/user` endpoint with anon key and bearer token, caps response size, and matches returned user ID against token subject. Test is **NOT RUN**. |
| Rotation / clock skew | **NOT RUN** — no live JWKS rotation test was run. Code sets a 10-minute refresh interval and 30-second leeway; key-rotation behavior and boundary-clock cases remain unverified. |

Correction applied: `RequireAuth` accepted case-insensitive `Bearer` schemes but stripped only exact-case `Bearer `, causing lowercase `bearer valid` to pass the scheme check and then be sent to verification with the prefix still attached. Extraction now splits scheme/token and trims the token consistently. The existing middleware test already covers lowercase scheme, but is **NOT RUN** without Go.

### PostgreSQL / RLS / migration review

There is one migration file (`20261123000100_stage0_foundation.sql`) and two pgTAP files (`schema.sql`, `rls.sql`). The schema suite has 30 assertions for all 18 application tables, key FKs/indexes/append-only triggers, RLS flags, a representative constraint, and PostGIS distance. The RLS suite has 14 assertions covering anonymous denial, passenger/driver row isolation, unauthorized writes, and an attempted privileged audit mutation. These checks were added/expanded during this verification request. Their requested clean-DB apply and pgTAP execution are **BLOCKED** because Docker, Supabase CLI, and `psql` are absent. Table/constraint/index presence, PostGIS behavior, grants, row isolation, denied writes, and append-only trigger behavior are therefore **NOT RUN**, not passed.

Static review found RLS enabled on all 18 application tables. Direct app grants are limited to self-scoped profile/passenger data and reads of drivers, vehicles, and active service areas; tables without policies/grants remain inaccessible to app roles. The profile update grant is column-limited. Event log, cash ledger, and admin audit update/delete triggers raise an exception. Service-role has broad table access by design and bypasses RLS; it must not be used by this API. The only `SECURITY DEFINER` function is the auth-user profile trigger; it has `search_path = ''`, schema-qualified table names, and execute revoked from API roles. Trigger behavior is **NOT RUN**.

The migration creates `e_go_api` as `NOLOGIN`, `NOINHERIT`, `NOBYPASSRLS` and grants it membership in `authenticated`. It deliberately does not create the runtime login/password; local secure provisioning is documented. Therefore the prompt's required assertion that the configured connection role has only the intended membership/permissions is **BLOCKED** pending local DB provisioning and inspection. Do not point the API at `postgres` or `service_role`.

### Database transaction-context verification

Static review confirms `WithUserTx` opens one pgx transaction, uses `SET LOCAL ROLE authenticated`, sets `request.jwt.claim.sub` and JSON `request.jwt.claims` transaction-locally from a UUID supplied by the verified principal, then commits or rolls back. This is separate from role switching; the code explicitly sets claims rather than assuming `SET ROLE` authenticates a user. `SET LOCAL` should reset at transaction end, but pool reuse and `auth.uid()`/RLS behavior are **NOT RUN**.

Added `internal/platform/database/user_tx_integration_test.go`, an opt-in integration test requiring `DATABASE_URL` and `SUPABASE_TEST_USER_ID` for an existing local Auth user. It checks the login role is neither superuser nor BYPASSRLS, has only the expected direct `e_go_api` membership, can assume `authenticated`, and has no direct profile read, schema/database create, or `service_role` membership; inside `WithUserTx` it checks `current_user`, `session_user`, `auth.uid()`, claims, and self-only profile visibility; after commit it checks transaction claims did not leak through a single-connection pool. The test is **NOT RUN** because no Go toolchain or local database is available.

### SQLC

`sqlc.yaml` and `sql/queries/health.sql` exist, but `generated/db` does not. There are no application data queries yet; the only query is `SELECT 1` for health and it is not used as a business repository. Generation and generated-code compilation are **NOT RUN** because sqlc and Go are absent. Parser compatibility with the full Supabase migration, including extensions/functions/roles, remains a validation blocker.

### Corrections and remaining blockers

- Corrected lowercase/mixed-case Bearer token extraction in `internal/middleware/auth.go`.
- Corrected `Dockerfile` to copy `go.mod` without requiring the currently absent `go.sum`; `go mod tidy` must still generate and commit `go.sum` before a reproducible Docker build is considered verified.
- Added the opt-in database-context integration test described above.
- No migration SQL was modified because its runtime behavior could not be safely tested without a local Supabase database.
- Overall Stage 0 quality gate: **FAIL** (critical required validations are **BLOCKED/NOT RUN**). Resolve tool installation, run every command and DB check above, fix any failures, and update this report with captured outputs before treating Stage 0 as verified.
- No production Supabase project was accessed. `.env.example` remains placeholder-only. Stop here; Stage 1 requires explicit owner approval.

## Limitations and Stage 1 deferrals

The current database migration and RLS suite still require local Supabase/PostgreSQL execution. The runtime login role must be provisioned separately in a secure database console/secret manager. No production credential, Auth SMS provider, business route, SQLC application query, worker, notification delivery, frontend integration, or deployment was created. The Stage 0 report is the review gate; do not begin Stage 1 before explicit owner approval.
