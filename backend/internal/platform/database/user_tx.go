package database

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type userClaims struct {
	Subject string `json:"sub"`
	Role    string `json:"role"`
	Aud     string `json:"aud"`
}

// WithUserTx runs a database callback under the authenticated PostgreSQL role
// with claims copied only from a JWT-verified principal.
func WithUserTx(ctx context.Context, pool *pgxpool.Pool, subject uuid.UUID, callback func(pgx.Tx) error) (err error) {
	if subject == uuid.Nil {
		return errors.New("verified database subject is required")
	}
	if callback == nil {
		return errors.New("transaction callback is required")
	}
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin user transaction: %w", err)
	}
	committed := false
	defer func() {
		if committed {
			return
		}
		rollbackCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if rollbackErr := tx.Rollback(rollbackCtx); rollbackErr != nil && !errors.Is(rollbackErr, pgx.ErrTxClosed) {
			err = errors.Join(err, fmt.Errorf("rollback user transaction: %w", rollbackErr))
		}
	}()

	if _, err = tx.Exec(ctx, "set local role authenticated"); err != nil {
		return fmt.Errorf("set authenticated database role: %w", err)
	}
	claims, err := json.Marshal(userClaims{Subject: subject.String(), Role: "authenticated", Aud: "authenticated"})
	if err != nil {
		return fmt.Errorf("encode database claims: %w", err)
	}
	if _, err = tx.Exec(ctx,
		"select set_config('request.jwt.claim.sub', $1, true), set_config('request.jwt.claims', $2, true)",
		subject.String(), string(claims),
	); err != nil {
		return fmt.Errorf("set transaction-local database claims: %w", err)
	}
	if err = callback(tx); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit user transaction: %w", err)
	}
	committed = true
	return nil
}
