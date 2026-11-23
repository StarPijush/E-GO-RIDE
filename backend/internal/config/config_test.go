package config

import "testing"

func TestLoadAcceptsSafeLocalConfiguration(t *testing.T) {
	cfg, err := load(lookup(map[string]string{
		"APP_ENV": "local", "APP_PORT": "8080", "APP_LOG_LEVEL": "info",
		"DATABASE_URL": "postgres://e_go_api_login:local@127.0.0.1:54322/postgres",
		"SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_ANON_KEY": "local-anon-placeholder",
		"SUPABASE_JWKS_URL": "http://127.0.0.1:54321/auth/v1/.well-known/jwks.json",
		"SUPABASE_JWT_ISSUER": "http://127.0.0.1:54321/auth/v1", "SUPABASE_JWT_AUDIENCE": "authenticated",
		"CORS_ALLOWED_ORIGINS": "http://localhost:3000,http://localhost:3000",
	}))
	if err != nil {
		t.Fatalf("load config: %v", err)
	}
	if len(cfg.CORSOrigins) != 1 {
		t.Fatalf("expected duplicate origins to be removed, got %d", len(cfg.CORSOrigins))
	}
}

func TestLoadRejectsInsecureOrMismatchedProductionConfig(t *testing.T) {
	values := map[string]string{
		"APP_ENV": "production", "APP_PORT": "8080", "APP_LOG_LEVEL": "info",
		"DATABASE_URL": "postgres://e_go_api_login:secret@db.example.invalid/postgres",
		"SUPABASE_URL": "http://project.supabase.co", "SUPABASE_ANON_KEY": "anon-placeholder",
		"SUPABASE_JWKS_URL": "http://project.supabase.co/auth/v1/.well-known/jwks.json",
		"SUPABASE_JWT_ISSUER": "http://project.supabase.co/auth/v1", "SUPABASE_JWT_AUDIENCE": "authenticated",
		"CORS_ALLOWED_ORIGINS": "https://app.example.invalid",
	}
	if _, err := load(lookup(values)); err == nil {
		t.Fatal("expected production HTTP Supabase URL to be rejected")
	}

	values["SUPABASE_URL"] = "https://project.supabase.co"
	values["SUPABASE_JWKS_URL"] = "https://attacker.example.invalid/auth/v1/.well-known/jwks.json"
	values["SUPABASE_JWT_ISSUER"] = "https://project.supabase.co/auth/v1"
	if _, err := load(lookup(values)); err == nil {
		t.Fatal("expected mismatched JWKS host to be rejected")
	}
}

func TestLoadRejectsWildcardCORSAndBadPort(t *testing.T) {
	values := validValues()
	values["CORS_ALLOWED_ORIGINS"] = "https://*.example.invalid"
	if _, err := load(lookup(values)); err == nil {
		t.Fatal("expected wildcard CORS origin to be rejected")
	}
	values = validValues()
	values["APP_PORT"] = "70000"
	if _, err := load(lookup(values)); err == nil {
		t.Fatal("expected invalid port to be rejected")
	}
}

func lookup(values map[string]string) func(string) (string, bool) {
	return func(key string) (string, bool) {
		value, ok := values[key]
		return value, ok
	}
}

func validValues() map[string]string {
	return map[string]string{
		"APP_ENV": "local", "APP_PORT": "8080", "APP_LOG_LEVEL": "info",
		"DATABASE_URL": "postgres://e_go_api_login:local@127.0.0.1:54322/postgres",
		"SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_ANON_KEY": "local-anon-placeholder",
		"SUPABASE_JWKS_URL": "http://127.0.0.1:54321/auth/v1/.well-known/jwks.json",
		"SUPABASE_JWT_ISSUER": "http://127.0.0.1:54321/auth/v1", "SUPABASE_JWT_AUDIENCE": "authenticated",
		"CORS_ALLOWED_ORIGINS": "http://localhost:3000",
	}
}
