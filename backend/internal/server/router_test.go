package server

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/ego/e-go/backend/internal/config"
)

type readinessFunc func(context.Context) error

func (f readinessFunc) Ping(ctx context.Context) error { return f(ctx) }

func TestHealthAndReadiness(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	cfg := config.Config{CORSOrigins: []string{"http://localhost:3000"}}
	ready := NewRouter(cfg, readinessFunc(func(context.Context) error { return nil }), logger)
	for _, path := range []string{"/health", "/ready"} {
		res := httptest.NewRecorder()
		ready.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK || !strings.Contains(res.Body.String(), "status") {
			t.Errorf("%s: unexpected response %d %s", path, res.Code, res.Body.String())
		}
	}

	notReady := NewRouter(cfg, readinessFunc(func(context.Context) error { return errors.New("database password must not leak") }), logger)
	res := httptest.NewRecorder()
	notReady.ServeHTTP(res, httptest.NewRequest(http.MethodGet, "/ready", nil))
	if res.Code != http.StatusServiceUnavailable || strings.Contains(res.Body.String(), "database password") {
		t.Fatalf("readiness error was not safely reported: %d %s", res.Code, res.Body.String())
	}
}

func TestCORSDeniesUnknownOriginAndAllowsKnownOrigin(t *testing.T) {
	handler := NewRouter(config.Config{CORSOrigins: []string{"https://app.example.invalid"}}, readinessFunc(func(context.Context) error { return nil }), slog.New(slog.NewTextHandler(io.Discard, nil)))
	bad := httptest.NewRequest(http.MethodGet, "/health", nil)
	bad.Header.Set("Origin", "https://attacker.example.invalid")
	badResponse := httptest.NewRecorder()
	handler.ServeHTTP(badResponse, bad)
	if badResponse.Code != http.StatusForbidden {
		t.Fatalf("expected origin rejection, got %d", badResponse.Code)
	}
	good := httptest.NewRequest(http.MethodGet, "/health", nil)
	good.Header.Set("Origin", "https://app.example.invalid")
	goodResponse := httptest.NewRecorder()
	handler.ServeHTTP(goodResponse, good)
	if goodResponse.Code != http.StatusOK || goodResponse.Header().Get("Access-Control-Allow-Origin") != "https://app.example.invalid" {
		t.Fatalf("known origin was not allowed: %d", goodResponse.Code)
	}
}
