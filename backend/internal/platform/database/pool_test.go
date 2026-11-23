package database

import (
	"context"
	"testing"
)

func TestNewPoolRejectsMalformedDatabaseURL(t *testing.T) {
	if _, err := NewPool(context.Background(), "not-a-postgres-url"); err == nil {
		t.Fatal("expected malformed database URL to be rejected")
	}
}

func TestNewPoolBuildsPoolWithoutOpeningConnections(t *testing.T) {
	pool, err := NewPool(context.Background(), "postgres://user:pass@127.0.0.1:5432/db")
	if err != nil {
		t.Fatalf("create pool: %v", err)
	}
	pool.Close()
}
