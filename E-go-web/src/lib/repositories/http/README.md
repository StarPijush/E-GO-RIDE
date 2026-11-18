# HTTP adapters (stubs)

These five files are the place where the real backend takes over. Today every
method returns a failure result:

```ts
{ ok: false, error: { code: 'unknown', message: 'HTTP adapter is not implemented. ...' } }
```

## How to swap the mock for the API

1. Implement the classes in this folder. Every class implements the matching
   interface of `src/lib/repositories/types.ts` and takes
   `(baseUrl: string, fetchImpl: typeof fetch = fetch)` as constructor
   arguments, so a test can inject its own `fetch`.
2. Map the HTTP responses to `Result` (`{ ok: true, data }` /
   `{ ok: false, error: AppError }`). Expected failures must never throw -
   they are returned as an error result.
3. Change **one** function: `createRepositories()` in
   `src/lib/repositories/index.ts`.

```ts
export function createRepositories(options: RepositoryOptions = {}): Repositories {
  const baseUrl = env.NEXT_PUBLIC_API_BASE_URL;
  // ... switch between the mock and the HTTP adapters here ...
}
```

No screen, store or component changes are needed: screens and stores only
know `getRepositories()` and the interfaces.

## Rules for the implementation

- `NEXT_PUBLIC_*` values are public - never put a secret in the base URL.
- The mock session is a browser token; the real API moves the session to an
  httpOnly cookie (architecture §11).
- Client side OTP rate limits (5 attempts, 30 s cooldown) are UX only - the
  server has to rate limit on its own.
- Validate every payload with the Zod schemas of `src/lib/domain/schemas.ts`
  before it enters the app.
