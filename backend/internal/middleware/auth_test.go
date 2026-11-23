package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ego/e-go/backend/internal/platform/supabase"
	"github.com/google/uuid"
)

type verifierFunc func(context.Context, string) (supabase.Principal, error)

func (f verifierFunc) Verify(ctx context.Context, token string) (supabase.Principal, error) {
	return f(ctx, token)
}

func TestRequireAuthRejectsMissingAndInvalidTokens(t *testing.T) {
	verifier := verifierFunc(func(context.Context, string) (supabase.Principal, error) {
		return supabase.Principal{}, supabase.ErrInvalidToken
	})
	handler := RequireAuth(verifier)(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	for _, authorization := range []string{"", "Basic token", "Bearer bad"} {
		req := httptest.NewRequest(http.MethodGet, "/private", nil)
		req.Header.Set("Authorization", authorization)
		res := httptest.NewRecorder()
		handler.ServeHTTP(res, req)
		if res.Code != http.StatusUnauthorized {
			t.Errorf("authorization %q: expected 401, got %d", authorization, res.Code)
		}
	}
}

func TestRequireAuthStoresVerifiedSubject(t *testing.T) {
	want := uuid.MustParse("550e8400-e29b-41d4-a716-446655440000")
	verifier := verifierFunc(func(_ context.Context, token string) (supabase.Principal, error) {
		if token != "valid" {
			return supabase.Principal{}, supabase.ErrInvalidToken
		}
		return supabase.Principal{Subject: want}, nil
	})
	handler := RequireAuth(verifier)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		principal, ok := PrincipalFromContext(r.Context())
		if !ok || principal.Subject != want {
			t.Error("verified principal missing from request context")
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	req := httptest.NewRequest(http.MethodGet, "/private", nil)
	req.Header.Set("Authorization", "bearer valid")
	res := httptest.NewRecorder()
	handler.ServeHTTP(res, req)
	if res.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d", res.Code)
	}
}

func TestRequireAuthMapsIdentityProviderOutage(t *testing.T) {
	verifier := verifierFunc(func(context.Context, string) (supabase.Principal, error) {
		return supabase.Principal{}, errors.Join(supabase.ErrAuthUnavailable, errors.New("private transport detail"))
	})
	handler := RequireAuth(verifier)(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	req := httptest.NewRequest(http.MethodGet, "/private", nil)
	req.Header.Set("Authorization", "Bearer token")
	res := httptest.NewRecorder()
	handler.ServeHTTP(res, req)
	if res.Code != http.StatusServiceUnavailable || res.Body.String() == "" {
		t.Fatalf("expected safe 503 response, got %d", res.Code)
	}
}
