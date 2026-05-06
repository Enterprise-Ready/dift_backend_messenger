package httpadapter

import (
	"context"
	"encoding/json"
	"net/http"

	"dift_backend_go/notification-service/pkg/health"
	"dift_backend_go/notification-service/pkg/metrics"
	"dift_backend_go/notification-service/pkg/notificationguard"
)

type GenericHandler struct {
	dispatch func(ctx context.Context, payload map[string]any) error
}

func NewGenericHandler(dispatch func(ctx context.Context, payload map[string]any) error) *GenericHandler {
	return &GenericHandler{dispatch: dispatch}
}

func (h *GenericHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(health.Live("notification-service", "travel-pattern"))
	})
	mux.HandleFunc("/health/live", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(health.Live("notification-service", "travel-pattern"))
	})
	mux.HandleFunc("/health/ready", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(health.Ready("notification-service", "travel-pattern"))
	})
	mux.HandleFunc("/metrics/business", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(metrics.JSON())
	})
	mux.HandleFunc("/api/v1/notifications/send", h.handleDispatch)
	mux.HandleFunc("/api/v1/notifications/event", h.handleDispatch)
}

func (h *GenericHandler) handleDispatch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	var payload map[string]any
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]any{"error": "invalid_json"})
		return
	}
	if err := notificationguard.ValidatePayload(payload); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]any{"error": err.Error()})
		return
	}
	if err := h.dispatch(r.Context(), payload); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(map[string]any{"error": "dispatch_failed"})
		return
	}
	w.WriteHeader(http.StatusAccepted)
	_ = json.NewEncoder(w).Encode(map[string]any{"accepted": true})
}
