package app

import (
	"context"
	"net/http"
	"time"

	"dift_backend_go/notification-service/internal/integration/event"
	mqtt "dift_backend_go/notification-service/internal/integration/mqtt_client"
	"dift_backend_go/notification-service/internal/service"
)

type App struct {
	HTTPServer     *http.Server
	Service        *service.GenericNotificationService
	EventConsumer  event.Client
	EventPublisher event.Publisher
	MQTTClient     mqtt.Client
	cancel         context.CancelFunc
}

func (a *App) Start(ctx context.Context) error {
	listenCtx, cancel := context.WithCancel(ctx)
	a.cancel = cancel
	go a.Service.StartListening(listenCtx)
	return a.HTTPServer.ListenAndServe()
}

func (a *App) Shutdown(ctx context.Context) error {
	if a.cancel != nil {
		a.cancel()
	}
	if a.HTTPServer != nil {
		_ = a.HTTPServer.Shutdown(ctx)
	}
	done := make(chan struct{})
	go func() {
		if a.EventPublisher != nil {
			_ = a.EventPublisher.Close()
		}
		if a.EventConsumer != nil {
			_ = a.EventConsumer.Close()
		}
		if a.MQTTClient != nil {
			a.MQTTClient.Close()
		}
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(10 * time.Second):
	}
	return nil
}
