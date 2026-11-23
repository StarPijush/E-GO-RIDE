# Local development

## Prerequisites

- Go 1.27+ and SQLC 1.31+ for the API and generated database package.
- Docker Desktop for the local Supabase stack.
- Supabase CLI 3.1 or later for migration apply/diff and database tests.

At Stage 0 inspection, Go, SQLC, Docker, Supabase CLI, and `psql` are not on PATH. The SQL migration and pgTAP suite therefore have not been executed locally.

## Setup

1. Install Go, SQLC, Docker Desktop, and Supabase CLI using their official installation instructions.
2. From `backend/`, copy `.env.example` to `.env` for local-only settings.
3. Run `supabase start`; use only the local URL and keys printed by the CLI.
4. Run `supabase db reset` to apply migrations and local seeds.
5. From `backend/`, run `go mod download`, `sqlc generate`, `gofmt -w .`, `go vet ./...`, and `go test ./...`.
6. Run `supabase test db` for pgTAP database tests.

No production/staging project ref or secret is checked in. Create separate Supabase projects for staging and production in the owner's account, configure secrets in the hosting environment, and link the CLI only after the project owner authorizes that connection. Do not commit `.env` files.

## Database role provisioning

The migration creates the `NOLOGIN`, `NOINHERIT`, `NOBYPASSRLS` group role `e_go_api`, which can `SET ROLE authenticated`. Provision a separate login role using the managed database console and a secret manager; give it membership in `e_go_api`, `NOINHERIT`, `NOBYPASSRLS`, and no owner/service-role membership. Set that login in `DATABASE_URL`. Do not use the default `postgres` or `service_role` credentials for the API.

## Environment variables

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `APP_ENV` are public app configuration. `SUPABASE_SERVICE_ROLE_KEY` and `DATABASE_URL` are backend-only secrets; they are included only as obvious local placeholders in `.env.example`. Client-facing validation rejects the presence of the service-role variable. Use separate credentials per environment and never paste production secrets into source or Flutter/browser configuration.
