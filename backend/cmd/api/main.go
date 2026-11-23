package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ego/e-go/backend/internal/config"
	"github.com/ego/e-go/backend/internal/platform/database"
	"github.com/ego/e-go/backend/internal/platform/supabase"
	"github.com/ego/e-go/backend/internal/server"
)

func main() {
	if err := run(); err != nil {
		slog.Error("api stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: cfg.LogLevel}))
	slog.SetDefault(logger)

	rootCtx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	pool, err := database.NewPool(rootCtx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	verifier, err := supabase.NewVerifier(rootCtx, cfg)
	if err != nil {
		return err
	}
	defer verifier.Close()

	handler := server.NewRouter(cfg, pool, logger)
	apiServer := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      20 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    16 << 10,
	}

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("http server listening", "port", cfg.Port, "environment", cfg.Environment)
		serveErr <- apiServer.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	case <-rootCtx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := apiServer.Shutdown(shutdownCtx); err != nil {
			_ = apiServer.Close()
			return err
		}
		return nil
	}
}
