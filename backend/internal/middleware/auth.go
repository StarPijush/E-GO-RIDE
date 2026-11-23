package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/ego/e-go/backend/internal/platform/supabase"
	"github.com/ego/e-go/backend/internal/shared/response"
	"github.com/google/uuid"
)

type TokenVerifier interface {
	Verify(context.Context, string) (supabase.Principal, error)
}

type principalContextKey struct{}

func PrincipalFromContext(ctx context.Context) (supabase.Principal, bool) {
	principal, ok := ctx.Value(principalContextKey{}).(supabase.Principal)
	return principal, ok
}

func RequireAuth(verifier TokenVerifier) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			scheme, token, hasToken := strings.Cut(header, " ")
			if !hasToken || !strings.EqualFold(scheme, "Bearer") {
				response.Error(w, http.StatusUnauthorized, "unauthorized", "A valid access token is required.")
				return
			}
			token = strings.TrimSpace(token)
			if token == "" {
				response.Error(w, http.StatusUnauthorized, "unauthorized", "A valid access token is required.")
				return
			}
			principal, err := verifier.Verify(r.Context(), token)
			if err != nil {
				if errors.Is(err, supabase.ErrAuthUnavailable) {
					response.Error(w, http.StatusServiceUnavailable, "auth_unavailable", "Authentication is temporarily unavailable.")
					return
				}
				response.Error(w, http.StatusUnauthorized, "unauthorized", "A valid access token is required.")
				return
			}
			if principal.Subject == uuid.Nil {
				response.Error(w, http.StatusUnauthorized, "unauthorized", "A valid access token is required.")
				return
			}
			ctx := context.WithValue(r.Context(), principalContextKey{}, principal)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
