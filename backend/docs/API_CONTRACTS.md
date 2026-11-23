# API contracts (v1)

The Go API currently implements only `GET /health` and `GET /ready` (also specified in `api/openapi.yaml`). No business endpoint, RPC, webhook, or Realtime publication is implemented in Stage 0. Planned contracts follow `../toto-go-blueprint/13-API-CONTRACTS.md` plus its v2 additions; ride states follow normative `20-STATE-MACHINE.md`. Go request decoding rejects unknown fields and trailing JSON values.

Global rules: Supabase JWT bearer authentication; actor identity comes from the verified JWT, never a caller-supplied user ID. Error envelope is `{error:{code,message,details?}}`. Mutations use `X-Idempotency-Key`; trip mutations also use `If-Match` revision. State mutation and outbox/event writes must be atomic. Validation failure does not mutate state.

| Implemented operation | Method | Auth | Request → response | Status |
|---|---|---|---|---|
| Liveness | `GET /health` | None | none → `{status:"ok"}` | IMPLEMENTED |
| Readiness | `GET /ready` | None | none → `{status:"ready"}` or safe 503 | IMPLEMENTED |

| Operation | Method | Auth / role | Request → response | Validation, authorization, idempotency | Status |
|---|---|---|---|---|---|
| Request OTP | `POST /auth/otp/request` | Public, rate-limited | `{phone}` → `{cooldown_seconds}` | E.164; invalid/unsupported phone, 429 limit; no request-key requirement | CONTRACT_ONLY |
| Verify OTP | `POST /auth/otp/verify` | Public, rate-limited | `{phone, code}` → access/refresh token + profile | 6 digits; ≤3 attempts/request, lockout after limit; replay policy per Auth provider | CONTRACT_ONLY |
| Refresh session | `POST /auth/refresh` | Valid refresh token | `{refresh_token}` → rotated access/refresh token | invalid/expired token; provider rotation policy | CONTRACT_ONLY |
| Read profile | `GET /me` | Authenticated passenger/driver | none → own user/profile/saved places/contacts | JWT identity only; no caller-supplied profile id | CONTRACT_ONLY |
| Update profile | `PUT /me` | Authenticated passenger/driver | allowed profile fields → updated own profile | role/admin fields rejected; body schema + own-row authorization | CONTRACT_ONLY |
| Read config | `GET /app-config` | Authenticated | none → typed config + ETag | 304 on matching ETag; read-only | CONTRACT_ONLY |
| Set driver availability | `POST /driver/status` | Approved driver | `{online:boolean}` → current status | approval + fresh heartbeat; unapproved/expired docs; idempotent desired-state write | CONTRACT_ONLY |
| Read pending offer | `GET /driver/offers/pending` | Approved driver | none → own offer or null | offer ownership; no passenger address before acceptance | CONTRACT_ONLY |
| Submit driver fare | `POST /ride-requests/{id}/offers` | Approved driver with pending offer | `{fare}` → quote/offer | positive whole INR rupees; server-stamped expiry; role/offer ownership; idempotency key | CONTRACT_ONLY |
| Decline offer | `POST /offers/{id}/decline` | Offer's driver | `{}` → terminal offer | pending state/owner; 404 or already-terminal response; idempotency key | CONTRACT_ONLY |
| Create request | `POST /ride-requests` | Authenticated passenger | intent UUID + pickup/drop → request id, `quote_pending`, config snapshot | coordinates valid/in service area, drop ≥50m away; one open request; 409/422/412; same intent UUID replays result | CONTRACT_ONLY |
| Read request and quotes | `GET /ride-requests/{id}` | Owning passenger | none → state, visible offers/quotes, reason | owner-scoped; 404 is terminal not-found UX; polling min interval applies | CONTRACT_ONLY |
| Accept quote | `POST /ride-requests/{id}/offers/{offer_id}/accept` | Owning passenger | quote id → trip id, pickup-code delivery | quote ownership/unexpired; 410 expired, 409 race; idempotency key; atomic CAS | CONTRACT_ONLY |
| Cancel request | `POST /ride-requests/{id}/cancel` | Owning passenger | reason id, conditional text, location snapshot → cancelled result | server reason catalogue; 404/409; idempotency key; cannot cancel accepted trip through request path | CONTRACT_ONLY |
| Read trip | `GET /trips/{id}` | Assigned passenger or driver | none → authoritative trip + revision | participant check; 404 maps to not-found terminal path | CONTRACT_ONLY |
| Start trip | `POST /trips/{id}/start` | Assigned driver | `{pickup_code}` + `If-Match` revision → trip snapshot | code, state, owner and revision; wrong code/409; idempotency key | CONTRACT_ONLY |
| Complete trip | `POST /trips/{id}/complete` | Assigned driver | `{drop_code}` + `If-Match` revision → completed/pending-cash trip | state, code/geofence, owner, revision; 412/409; cash may be absent; idempotency key | CONTRACT_ONLY |
| Cancel trip | `POST /trips/{id}/cancel` | Assigned passenger/driver; admin separate | reason id/text + `If-Match` → terminal trip | canonical allowed transition/confirmation; 404/409; idempotency key | CONTRACT_ONLY |
| Declare cash | `POST /trips/{id}/cash-declaration` | Assigned driver | `{amount}` → ledger entry and cash status | integer rupees; completed trip/owner; 400/409; mandatory idempotency key | CONTRACT_ONLY |
| Read history | `GET /trips?history=true&cursor` | Authenticated participant | cursor → items + next cursor | participant-scoped pagination; no idempotency | CONTRACT_ONLY |
| Submit rating | `POST /trips/{id}/rating` | Eligible trip participant | `{stars,note?}` → rating | stars 1–5, one per actor/trip; participant check | CONTRACT_ONLY |
| Create share link | `GET /trips/{id}/share` | Owning passenger | none → short-lived share URL | participant check; single-purpose token expires at trip end + 24h; revocable | CONTRACT_ONLY |
| Upload location batch | `POST /driver/location` | Authenticated driver | up to 10 `{lat,lng,heading,recorded_at}` → accepted count | driver identity, monotonic times, freshness/frequency/plausibility; points older than 90s discarded | CONTRACT_ONLY |
| Admin driver/trip/ticket/config operations | `GET/POST /admin/drivers[...]`, `GET /admin/trips`, `POST /admin/tickets/{id}/close`, `GET/PUT /admin/config`, `GET /admin/dispatch-log?request_id` | Server-verified admin; fine-grained role policy blocked on Q-9 | operation-specific body → result | actor/role checks; every mutation atomically writes audit; 403/409/412 | BLOCKED_BY_DECISION |
| Admin trip/driver overrides | `/admin/trips/{id}/{complete\|cancel\|adjust-cash}`, `/admin/drivers/{id}/{approve\|suspend}` | Admin, owner/helper permission unresolved | reason/evidence + intended change → audited result | role split, state and audit-write checks; 403/409/412; idempotency key | BLOCKED_BY_DECISION |
| Trip realtime | `trip:{id}` | Assigned passenger/driver only | state, revision, update time, permitted driver position/cash status | scoped channel authorization; poll fallback; no broad feed | NOT_IMPLEMENTED |
| Offer realtime | `offers:{driver_id}` | That approved driver only | created/cancelled offer event | per-driver channel authorization | NOT_IMPLEMENTED |
| SMS callback | Internal delivery webhook | Provider signature only | delivery status → acknowledgement | signature check, replay guard; no user JWT | NOT_IMPLEMENTED |

The canonical API document contains older examples with `open/matched/accepted`, plus a second driver accept path. Those conflict with the v2 state machine and v2 passenger accept path. The normative FSM and v2 passenger accept path take precedence for this Stage 0 snapshot. These contract choices require review before Stage 1 implementation.
