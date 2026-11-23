package supabase

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	"github.com/ego/e-go/backend/internal/config"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

var (
	ErrInvalidToken = errors.New("invalid access token")
	ErrAuthUnavailable = errors.New("Supabase Auth is unavailable")
)

var asymmetricMethods = []string{"ES256", "RS256", "EdDSA"}

type Principal struct {
	Subject uuid.UUID
}

type Claims struct {
	jwt.RegisteredClaims
	Role string `json:"role"`
}

type Verifier struct {
	keys       jwt.Keyfunc
	issuer     string
	audience   string
	userURL    string
	anonKey    string
	client     *http.Client
	cancelKeys context.CancelFunc
}

func NewVerifier(ctx context.Context, cfg config.Config) (*Verifier, error) {
	keysCtx, cancel := context.WithCancel(ctx)
	keys, err := keyfunc.NewDefaultOverrideCtx(keysCtx, []string{cfg.JWKSURL}, keyfunc.Override{
		Client:          supabaseHTTPClient(5 * time.Second),
		HTTPTimeout:     5 * time.Second,
		RefreshInterval: 10 * time.Minute,
	})
	if err != nil {
		cancel()
		return nil, fmt.Errorf("configure Supabase JWKS verifier: %w", err)
	}
	return &Verifier{
		keys: keys.Keyfunc,
		issuer: cfg.JWTIssuer,
		audience: cfg.JWTAudience,
		userURL: strings.TrimRight(cfg.SupabaseURL, "/") + "/auth/v1/user",
		anonKey: cfg.AnonKey,
		client: supabaseHTTPClient(4 * time.Second),
		cancelKeys: cancel,
	}, nil
}

func (v *Verifier) Close() {
	v.cancelKeys()
}

func (v *Verifier) Verify(ctx context.Context, rawToken string) (Principal, error) {
	if rawToken == "" || len(rawToken) > 8192 {
		return Principal{}, ErrInvalidToken
	}

	unverified := new(Claims)
	parsed, _, err := jwt.NewParser().ParseUnverified(rawToken, unverified)
	if err != nil || parsed == nil || parsed.Method == nil {
		return Principal{}, ErrInvalidToken
	}
	if parsed.Method.Alg() == jwt.SigningMethodHS256.Alg() {
		return v.verifyLegacyWithAuthServer(ctx, rawToken, unverified)
	}
	if !contains(asymmetricMethods, parsed.Method.Alg()) {
		return Principal{}, ErrInvalidToken
	}

	claims := new(Claims)
	verified, err := jwt.ParseWithClaims(rawToken, claims, v.keys,
		jwt.WithValidMethods(asymmetricMethods),
		jwt.WithIssuer(v.issuer),
		jwt.WithAudience(v.audience),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
		jwt.WithLeeway(30*time.Second),
	)
	if err != nil || verified == nil || !verified.Valid {
		return Principal{}, ErrInvalidToken
	}
	return principalFromClaims(claims)
}

func (v *Verifier) verifyLegacyWithAuthServer(ctx context.Context, rawToken string, claims *Claims) (Principal, error) {
	if err := v.validateClaims(claims); err != nil {
		return Principal{}, ErrInvalidToken
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, v.userURL, nil)
	if err != nil {
		return Principal{}, ErrAuthUnavailable
	}
	request.Header.Set("apikey", v.anonKey)
	request.Header.Set("Authorization", "Bearer "+rawToken)
	response, err := v.client.Do(request)
	if err != nil {
		return Principal{}, ErrAuthUnavailable
	}
	defer response.Body.Close()
	if response.StatusCode == http.StatusUnauthorized || response.StatusCode == http.StatusForbidden {
		return Principal{}, ErrInvalidToken
	}
	if response.StatusCode != http.StatusOK {
		return Principal{}, ErrAuthUnavailable
	}
	var user struct {
		ID string `json:"id"`
	}
	decoder := json.NewDecoder(io.LimitReader(response.Body, 64<<10))
	if err := decoder.Decode(&user); err != nil {
		return Principal{}, ErrAuthUnavailable
	}
	var extra any
	if err := decoder.Decode(&extra); !errors.Is(err, io.EOF) {
		return Principal{}, ErrAuthUnavailable
	}
	if user.ID != claims.Subject {
		return Principal{}, ErrInvalidToken
	}
	return principalFromClaims(claims)
}

func supabaseHTTPClient(timeout time.Duration) *http.Client {
	return &http.Client{
		Timeout: timeout,
		CheckRedirect: func(_ *http.Request, _ []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}

func (v *Verifier) validateClaims(claims *Claims) error {
	if claims.Role != "authenticated" {
		return ErrInvalidToken
	}
	validator := jwt.NewValidator(
		jwt.WithIssuer(v.issuer),
		jwt.WithAudience(v.audience),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
		jwt.WithLeeway(30*time.Second),
	)
	return validator.Validate(claims)
}

func principalFromClaims(claims *Claims) (Principal, error) {
	if claims.Role != "authenticated" || claims.Subject == "" || claims.IssuedAt == nil {
		return Principal{}, ErrInvalidToken
	}
	subject, err := uuid.Parse(claims.Subject)
	if err != nil {
		return Principal{}, ErrInvalidToken
	}
	return Principal{Subject: subject}, nil
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
}
