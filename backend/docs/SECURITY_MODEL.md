# Security model

## Trust boundaries

- Supabase Auth verifies phone OTP and supplies `auth.uid()`; the database trigger creates a passenger-default E-GO profile. A client cannot set its role through profile insert/update.
- `anon` and `authenticated` have no blanket public table grants. RLS is enabled everywhere; table access is denied unless explicitly granted and policy-scoped.
- Mobile/browser builds may contain only the Supabase URL and anon key. The service-role key and database credentials are server-side secrets only.
- Ride lifecycle, dispatch, driver approval, cash declaration, ledger correction, admin operations, and location ingestion are not directly writable by app roles.

## Current grants

| Principal | Allowed now |
|---|---|
| Anonymous | No application table access |
| Authenticated passenger | Read own profile and passenger settings; update own display name, locale, and passenger settings; read active service areas |
| Authenticated driver | The same own-profile access; read own driver/vehicle rows if provisioned |
| Admin/helper/support viewer | No direct table privileges yet; role matrix is not yet approved for implementation |
| Go API login | Dedicated non-owner `e_go_api_login`, `NOINHERIT`, `NOBYPASSRLS`; each user transaction sets `authenticated` and transaction-local JWT claims |
| Supabase service role | Not used by the Go API; never place in a client or API environment |

The owner/helper/support-viewer matrix in blueprint 12 is recorded, but Q-9 leaves staff and limits unconfirmed. Until approved, do not expose privileged rows through direct PostgREST grants. Future Go handlers must validate roles and row ownership on every operation; hidden controls are not authorization.

## JWT verification

The API uses the configured project's fixed JWKS endpoint and never follows token-supplied issuer URLs. For asymmetric Supabase keys it accepts ES256, RS256, or EdDSA, verifies the signature with cached/refreshing JWKS, then checks configured issuer/audience, expiry, issued-at, `role=authenticated`, and UUID subject. Unknown algorithms and `service_role` tokens are rejected. For legacy HS256 tokens, the API does not store or verify with the shared JWT secret; it checks claims and asks the configured Supabase Auth `/user` endpoint to verify the bearer token, then matches the returned user id. The anon key used for this Auth call is not privileged.

## Protected data and invariants

- Driver document paths are references to private storage, not public URLs. A future storage bucket must authorize each object by driver/admin role.
- Exact live locations are not selectable by ordinary users. Passenger location access is restricted to the passenger's assigned active trip.
- Ride state changes must validate actor, allowed transition, current revision, required codes, and idempotency in one database transaction; append event and outbox rows in the same transaction.
- Cash and admin audit tables reject UPDATE/DELETE at the database trigger boundary. Corrections are compensating ledger rows.
- RLS tests cover self isolation, protected role columns, and absence of client access to ride/ledger tables. Local Postgres execution is required before calling those policies verified.

## Not implemented

Phone rate limits and OTP lockout configuration, DLT SMS, session revocation policy, API rate limiting, business request validation, storage policies, admin MFA, location plausibility controls, and production key management are future work. No client can use the database foundation as a production ride backend yet.
