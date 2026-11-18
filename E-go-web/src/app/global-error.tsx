"use client";

/**
 * The last resort of the app.
 *
 * `global-error` replaces the root layout, so it may not use Tailwind
 * classes or the global stylesheet - everything is styled inline.
 */

export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html lang="en">
      <body
        style={{
          margin: 0,
          minHeight: "100dvh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: "1rem",
          background: "#F5F7FA",
          color: "#142B45",
          fontFamily: "system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif",
        }}
      >
        <div
          style={{
            width: "100%",
            maxWidth: "28rem",
            background: "#FFFFFF",
            border: "1px solid #E2E8F0",
            borderRadius: "16px",
            overflow: "hidden",
            boxShadow: "0 8px 24px rgb(20 43 69 / 0.08)",
          }}
        >
          <div style={{ height: "6px", background: "#FFC928" }} />

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "0.75rem",
              padding: "1.5rem",
            }}
          >
            <h1 style={{ margin: 0, fontSize: "1.5rem", fontWeight: 700 }}>E-GO</h1>

            <p style={{ margin: 0, fontSize: "1.125rem", fontWeight: 600 }}>
              Something went wrong.
            </p>

            <p style={{ margin: 0, fontSize: "0.875rem", color: "#5B6B7C" }}>
              The app could not start. Please try again.
            </p>

            <button
              type="button"
              onClick={() => reset()}
              style={{
                alignSelf: "flex-start",
                minHeight: "44px",
                padding: "0 1.5rem",
                borderRadius: "9999px",
                border: "none",
                background: "#FFC928",
                color: "#142B45",
                fontSize: "0.875rem",
                fontWeight: 600,
                fontFamily: "inherit",
                cursor: "pointer",
              }}
            >
              Try again
            </button>

            <p style={{ margin: 0, fontSize: "0.75rem", color: "#5B6B7C" }}>
              Your saved rides are still on this device.
            </p>
          </div>
        </div>
      </body>
    </html>
  );
}
