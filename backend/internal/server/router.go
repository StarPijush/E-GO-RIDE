package server

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/ego/e-go/backend/internal/config"
	"github.com/ego/e-go/backend/internal/middleware"
	"github.com/ego/e-go/backend/internal/shared/response"
	"github.com/go-chi/chi/v5"
)

type ReadinessChecker interface {
	Ping(context.Context) error
}

func NewRouter(cfg config.Config, readiness ReadinessChecker, logger *slog.Logger) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Recover(logger))
	r.Use(middleware.RequestLog(logger))
	r.Use(middleware.CORS(cfg.CORSOrigins))
	r.Use(middleware.MaxBodyBytes(1 << 20))

	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		response.JSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	r.Get("/ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := readiness.Ping(ctx); err != nil {
			logger.WarnContext(r.Context(), "readiness database check failed")
			response.Error(w, http.StatusServiceUnavailable, "not_ready", "The service is not ready.")
			return
		}
		response.JSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
	return r
}

