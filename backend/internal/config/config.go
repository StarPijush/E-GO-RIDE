package config

import (
	"fmt"
	"log/slog"
	"net/url"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Environment   string
	Port          string
	LogLevel      slog.Level
	DatabaseURL   string
	SupabaseURL   string
	AnonKey       string
	JWKSURL       string
	JWTIssuer     string
	JWTAudience   string
	CORSOrigins   []string
}

func Load() (Config, error) {
	return load(os.LookupEnv)
}

func load(lookup func(string) (string, bool)) (Config, error) {
	get := func(key string) (string, error) {
		value, ok := lookup(key)
		value = strings.TrimSpace(value)
		if !ok || value == "" {
			return "", fmt.Errorf("%s is required", key)
		}
		return value, nil
	}

	var cfg Config
	var err error
	if cfg.Environment, err = get("APP_ENV"); err != nil {
		return Config{}, err
	}
	if cfg.Environment != "local" && cfg.Environment != "staging" && cfg.Environment != "production" {
		return Config{}, fmt.Errorf("APP_ENV must be local, staging, or production")
	}
	cfg.Port, err = get("APP_PORT")
	if err != nil {
		return Config{}, err
	}
	port, parseErr := strconv.Atoi(cfg.Port)
	if parseErr != nil || port < 1 || port > 65535 {
		return Config{}, fmt.Errorf("APP_PORT must be a valid TCP port")
	}
	levelText, err := get("APP_LOG_LEVEL")
	if err != nil {
		return Config{}, err
	}
	if err := cfg.LogLevel.UnmarshalText([]byte(strings.ToLower(levelText))); err != nil {
		return Config{}, fmt.Errorf("APP_LOG_LEVEL must be debug, info, warn, or error")
	}
	if cfg.DatabaseURL, err = get("DATABASE_URL"); err != nil {
		return Config{}, err
	}
	if err := validateDatabaseURL(cfg.DatabaseURL); err != nil {
		return Config{}, err
	}
	if cfg.SupabaseURL, err = get("SUPABASE_URL"); err != nil {
		return Config{}, err
	}
	if cfg.AnonKey, err = get("SUPABASE_ANON_KEY"); err != nil {
		return Config{}, err
	}
	if cfg.JWKSURL, err = get("SUPABASE_JWKS_URL"); err != nil {
		return Config{}, err
	}
	if cfg.JWTIssuer, err = get("SUPABASE_JWT_ISSUER"); err != nil {
		return Config{}, err
	}
	if cfg.JWTAudience, err = get("SUPABASE_JWT_AUDIENCE"); err != nil {
		return Config{}, err
	}
	if err := validateSupabaseConfig(cfg); err != nil {
		return Config{}, err
	}
	origins, err := get("CORS_ALLOWED_ORIGINS")
	if err != nil {
		return Config{}, err
	}
	cfg.CORSOrigins, err = parseOrigins(origins)
	if err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func validateDatabaseURL(raw string) error {
	u, err := url.Parse(raw)
	if err != nil || (u.Scheme != "postgres" && u.Scheme != "postgresql") || u.Host == "" || u.User == nil {
		return fmt.Errorf("DATABASE_URL must be a PostgreSQL URL with a username")
	}
	return nil
}

func validateSupabaseConfig(cfg Config) error {
	base, err := url.Parse(cfg.SupabaseURL)
	if err != nil || (base.Scheme != "http" && base.Scheme != "https") || base.Host == "" || base.User != nil || base.RawQuery != "" || base.Fragment != "" {
		return fmt.Errorf("SUPABASE_URL must be an http(s) origin without credentials or query parameters")
	}
	if cfg.Environment != "local" && base.Scheme != "https" {
		return fmt.Errorf("SUPABASE_URL must use HTTPS outside local development")
	}
	wantJWKS := strings.TrimRight(cfg.SupabaseURL, "/") + "/auth/v1/.well-known/jwks.json"
	if cfg.JWKSURL != wantJWKS {
		return fmt.Errorf("SUPABASE_JWKS_URL must match the configured project's Auth JWKS endpoint")
	}
	wantIssuer := strings.TrimRight(cfg.SupabaseURL, "/") + "/auth/v1"
	if cfg.JWTIssuer != wantIssuer {
		return fmt.Errorf("SUPABASE_JWT_ISSUER must match the configured project's Auth issuer")
	}
	return nil
}

func parseOrigins(raw string) ([]string, error) {
	parts := strings.Split(raw, ",")
	origins := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		origin := strings.TrimSpace(part)
		u, err := url.Parse(origin)
		if err != nil || u.Host == "" || (u.Scheme != "http" && u.Scheme != "https") || u.Path != "" || u.RawQuery != "" || u.Fragment != "" || u.User != nil || strings.Contains(origin, "*") {
			return nil, fmt.Errorf("CORS_ALLOWED_ORIGINS must contain explicit http(s) origins without paths or wildcards")
		}
		if _, ok := seen[origin]; !ok {
			seen[origin] = struct{}{}
			origins = append(origins, origin)
		}
	}
	if len(origins) == 0 {
		return nil, fmt.Errorf("CORS_ALLOWED_ORIGINS must contain at least one origin")
	}
	return origins, nil
}
