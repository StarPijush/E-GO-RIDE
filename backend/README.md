# E-GO backend foundation

Stage 0 establishes a standalone Go HTTP API alongside Supabase Auth, PostgreSQL, PostGIS, and Realtime. The Go service verifies Supabase access tokens, manages a least-privilege pgx pool, exposes liveness/readiness endpoints, and provides database migration, RLS, SQLC, and API contract foundations. Business workflows remain unimplemented.

## Layout

- `supabase/`: local Supabase configuration, migrations, local seed entry point, and database tests.
- `cmd/api/`: API process entry point.
- `internal/`: configuration, HTTP middleware/server, Supabase JWT verification, pgx, responses, and validation.
- `sql/queries/`, `sqlc.yaml`, `generated/db/`: SQLC source and generated pgx types.
- `api/openapi.yaml`: implemented health/readiness contract.
- `tests/`: Go and Supabase pgTAP tests.
- `docs/`: architecture, schema, API, security, local setup, and implementation report.

The pre-existing empty `migrations/` and `src/` placeholders are retained. Supabase CLI migrations live in `supabase/migrations/` because that is the configured Supabase project root.

## Start locally

Install Go 1.27+, SQLC 1.31+, Docker Desktop, and Supabase CLI 3.1+, then follow [`docs/LOCAL_DEVELOPMENT.md`](docs/LOCAL_DEVELOPMENT.md). Copy `.env.example` only for local development. The API uses a dedicated database login and `authenticated` RLS role, never a service-role credential.

## Validation

From `backend/`, run `go test ./...`, `go vet ./...`, `gofmt -w .`, and `sqlc generate`. With local Supabase running, run `supabase db reset` and `supabase test db`. Exact execution results and missing tools are recorded in [`docs/STAGE_0_IMPLEMENTATION_REPORT.md`](docs/STAGE_0_IMPLEMENTATION_REPORT.md).

## Source of truth

The canonical design is `../toto-go-blueprint/`; `20-STATE-MACHINE.md` is normative for ride states. Latest repository audits are `../docs/audit/current-state/07-ARCHITECTURE_AUDIT.md` and `13-FINAL_AUDIT_REPORT.md`. The newer owner decision selects a separate Go API; it supersedes the earlier Edge Function direction without changing the Supabase data/auth platform.
