package database

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// TestWithUserTxRLSContext requires a local Supabase database and a real Auth
// user created in it. Set DATABASE_URL and SUPABASE_TEST_USER_ID to enable it.
func TestWithUserTxRLSContext(t *testing.T) {
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	subjectText := strings.TrimSpace(os.Getenv("SUPABASE_TEST_USER_ID"))
	if databaseURL == "" || subjectText == "" {
		t.Skip("requires DATABASE_URL and SUPABASE_TEST_USER_ID for local Supabase integration")
	}
	subject, err := uuid.Parse(subjectText)
	if err != nil {
		t.Fatalf("SUPABASE_TEST_USER_ID must be a UUID: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	poolConfig, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatalf("parse database configuration: %v", err)
	}
	poolConfig.MaxConns = 1
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		t.Fatalf("create database pool: %v", err)
	}
	defer pool.Close()

	var loginRole string
	var isSuperuser, bypassesRLS, canAssumeAPI, canAssumeAuth bool
	var canAssumeService, canCreateDatabase, canCreateSchema, canReadProfiles bool
	var unexpectedMemberships int
	err = pool.QueryRow(ctx, `
		select current_user,
		       r.rolsuper,
		       r.rolbypassrls,
		       pg_has_role(current_user, 'e_go_api', 'member'),
		       pg_has_role(current_user, 'authenticated', 'member'),
		       pg_has_role(current_user, 'service_role', 'member'),
		       has_database_privilege(current_user, current_database(), 'CREATE'),
		       has_schema_privilege(current_user, 'public', 'CREATE'),
		       has_table_privilege(current_user, 'public.profiles', 'SELECT'),
		       (select count(*)::integer from pg_auth_members m
		        where m.member = r.oid
		          and m.roleid <> (select oid from pg_roles where rolname = 'e_go_api'))
		from pg_roles r where r.rolname = current_user`).Scan(
		&loginRole, &isSuperuser, &bypassesRLS, &canAssumeAPI, &canAssumeAuth,
		&canAssumeService, &canCreateDatabase, &canCreateSchema, &canReadProfiles, &unexpectedMemberships,
	)
	if err != nil {
		t.Fatalf("inspect runtime database role: %v", err)
	}
	if isSuperuser || bypassesRLS || !canAssumeAPI || !canAssumeAuth || canAssumeService || canCreateDatabase || canCreateSchema || canReadProfiles || unexpectedMemberships != 0 {
		t.Fatalf("unsafe or incomplete API DB role %q: superuser=%t bypassrls=%t e_go_api_member=%t authenticated_member=%t service_role_member=%t database_create=%t public_schema_create=%t direct_profile_read=%t extra_memberships=%d", loginRole, isSuperuser, bypassesRLS, canAssumeAPI, canAssumeAuth, canAssumeService, canCreateDatabase, canCreateSchema, canReadProfiles, unexpectedMemberships)
	}

	err = WithUserTx(ctx, pool, subject, func(tx pgx.Tx) error {
		var currentRole, sessionRole, resolvedSubject string
		var claims string
		if err := tx.QueryRow(ctx, `
			select current_user, session_user, auth.uid()::text,
			       current_setting('request.jwt.claims', true)`).Scan(
			&currentRole, &sessionRole, &resolvedSubject, &claims,
		); err != nil {
			return err
		}
		if currentRole != "authenticated" || sessionRole != loginRole || resolvedSubject != subject.String() {
			return fmt.Errorf("unexpected transaction security context: role=%q session=%q uid=%q", currentRole, sessionRole, resolvedSubject)
		}
		var parsedClaims map[string]string
		if err := json.Unmarshal([]byte(claims), &parsedClaims); err != nil {
			return fmt.Errorf("decode transaction-local claims: %w", err)
		}
		if parsedClaims["sub"] != subject.String() || parsedClaims["role"] != "authenticated" {
			return fmt.Errorf("unexpected transaction-local claims: sub=%q role=%q", parsedClaims["sub"], parsedClaims["role"])
		}
		var visibleProfiles int
		if err := tx.QueryRow(ctx, `select count(*) from public.profiles`).Scan(&visibleProfiles); err != nil {
			return err
		}
		if visibleProfiles != 1 {
			return fmt.Errorf("RLS exposed %d profiles; expected only the verified user's profile", visibleProfiles)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("user-scoped transaction failed: %v", err)
	}

	var currentRole, subjectClaim string
	err = pool.QueryRow(ctx, `
		select current_user,
		       coalesce(current_setting('request.jwt.claim.sub', true), '')`).Scan(&currentRole, &subjectClaim)
	if err != nil {
		t.Fatalf("inspect pooled connection after transaction: %v", err)
	}
	if currentRole != loginRole || subjectClaim != "" {
		t.Fatalf("pooled connection leaked transaction context: role=%q sub=%q", currentRole, subjectClaim)
	}
}
