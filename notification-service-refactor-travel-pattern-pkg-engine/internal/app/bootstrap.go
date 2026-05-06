package app

import (
	"fmt"
	"net/http"
	"time"

	"dift_backend_go/notification-service/config"
	httpadapter "dift_backend_go/notification-service/internal/adapter/inbound/http"
	"dift_backend_go/notification-service/internal/integration/admin"
	"dift_backend_go/notification-service/internal/integration/event"
	mqtt "dift_backend_go/notification-service/internal/integration/mqtt_client"
	"dift_backend_go/notification-service/internal/service"
)

func Bootstrap(cfg *config.Config) (*App, error) {
	eventConsumer := event.NewEventBusConsumer(cfg.EventBusBrokers, cfg.EventBusGroup)
	eventPublisher := event.NewEventBusPublisher(cfg.EventBusBrokers)
	mqttClient := mqtt.NewMQTTClient(cfg.MQTTBroker, "notification-service", 1, cfg.MQTTSecure)
	adminClient := admin.NewClient(cfg.AdminServiceURL, cfg.AdminAuthToken, time.Duration(cfg.AdminTimeoutMS)*time.Millisecond)

	svc := service.NewGenericNotificationService(cfg, eventConsumer, mqttClient, eventPublisher, adminClient)

	mux := http.NewServeMux()
	handler := httpadapter.NewGenericHandler(svc.Dispatch)
	handler.Register(mux)

	wrapped := httpadapter.WithStandardMiddleware(mux)
	httpSrv := &http.Server{
		Addr:              ":" + itoa(cfg.HTTPPort),
		Handler:           wrapped,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       30 * time.Second,
	}

	return &App{HTTPServer: httpSrv, Service: svc, EventConsumer: eventConsumer, EventPublisher: eventPublisher, MQTTClient: mqttClient}, nil
}

func itoa(v int) string {
	if v <= 0 {
		return "2222"
	}
	return fmt.Sprintf("%d", v)
}
