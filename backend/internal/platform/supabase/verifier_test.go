package supabase

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func TestVerifierChecksSignatureClaimsRoleAndSubject(t *testing.T) {
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	wrongKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	want := uuid.New()
	verifier := &Verifier{
		keys: func(*jwt.Token) (any, error) { return &privateKey.PublicKey, nil },
		issuer: "https://project.example.invalid/auth/v1",
		audience: "authenticated",
		client: http.DefaultClient,
	}

	tests := []struct {
		name string
		claims Claims
		key *rsa.PrivateKey
		wantValid bool
	}{
		{name: "valid", claims: validClaims(verifier, want), key: privateKey, wantValid: true},
		{name: "wrong issuer", claims: func() Claims { c := validClaims(verifier, want); c.Issuer = "https://other.invalid/auth/v1"; return c }(), key: privateKey},
		{name: "wrong audience", claims: func() Claims { c := validClaims(verifier, want); c.Audience = []string{"anon"}; return c }(), key: privateKey},
		{name: "expired", claims: func() Claims { c := validClaims(verifier, want); c.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-time.Minute)); return c }(), key: privateKey},
		{name: "wrong role", claims: func() Claims { c := validClaims(verifier, want); c.Role = "service_role"; return c }(), key: privateKey},
		{name: "missing subject", claims: func() Claims { c := validClaims(verifier, want); c.Subject = ""; return c }(), key: privateKey},
		{name: "bad signature", claims: validClaims(verifier, want), key: wrongKey},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			raw := signClaims(t, tt.claims, tt.key, jwt.SigningMethodRS256)
			principal, err := verifier.Verify(context.Background(), raw)
			if tt.wantValid {
				if err != nil || principal.Subject != want {
					t.Fatalf("expected verified subject %s, got %s, %v", want, principal.Subject, err)
				}
			} else if err == nil {
				t.Fatal("expected invalid token to be rejected")
			}
		})
	}
}

func TestLegacyHS256UsesSupabaseAuthInsteadOfASharedSecret(t *testing.T) {
	want := uuid.New()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/auth/v1/user" || r.Header.Get("apikey") != "test-anon" || r.Header.Get("Authorization") == "" {
			t.Errorf("unexpected Supabase Auth request")
		}
		_ = json.NewEncoder(w).Encode(map[string]string{"id": want.String()})
	}))
	defer server.Close()
	verifier := &Verifier{
		issuer: "https://project.example.invalid/auth/v1",
		audience: "authenticated",
		userURL: server.URL + "/auth/v1/user",
		anonKey: "test-anon",
		client: server.Client(),
	}
	secret := []byte("not-a-production-secret")
	verifier.keys = func(*jwt.Token) (any, error) { return nil, ErrInvalidToken }
	raw := signClaims(t, validClaims(verifier, want), secret, jwt.SigningMethodHS256)

	principal, err := verifier.Verify(context.Background(), raw)
	if err != nil || principal.Subject != want {
		t.Fatalf("expected Auth-verified legacy token subject %s, got %s, %v", want, principal.Subject, err)
	}
}

func validClaims(verifier *Verifier, subject uuid.UUID) Claims {
	now := time.Now()
	return Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer: verifier.issuer, Subject: subject.String(), Audience: jwt.ClaimStrings{verifier.audience},
			ExpiresAt: jwt.NewNumericDate(now.Add(5 * time.Minute)), IssuedAt: jwt.NewNumericDate(now.Add(-time.Minute)),
		},
		Role: "authenticated",
	}
}

func signClaims(t *testing.T, claims Claims, key any, method jwt.SigningMethod) string {
	t.Helper()
	token := jwt.NewWithClaims(method, claims)
	token.Header["kid"] = "test-key"
	raw, err := token.SignedString(key)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}
