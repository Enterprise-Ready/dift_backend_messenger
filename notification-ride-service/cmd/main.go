package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"dift_backend_go/notification-service/config"
	"dift_backend_go/notification-service/internal/integration/event"
	mqtt "dift_backend_go/notification-service/internal/integration/mqtt_client"
	"dift_backend_go/notification-service/internal/service"
	"dift_backend_go/notification-service/internal/servicecore"
	eventing "dift_backend_go/notification-service/internal/servicecore/eventing"
)

func main() {
	_ = sc.NewEngineUnifiedBundle(sc.LoadEngineUnifiedConfigFromEnv("notification-ride-service"))
	cfg := config.LoadConfig()
	health := servicecore.HealthController("notification-service", "v1")
	log.Printf("service=%s version=%s status=%s", health.Service, health.Version, health.Status)

	rawEventBusConsumer := event.NewEventBusConsumer(cfg.EventBusBrokers, cfg.EventBusGroup)
	eventBusConsumer, err := eventing.NewReliableConsumer(rawEventBusConsumer)
	if err != nil {
		log.Fatalf("init reliable event consumer failed: %v", err)
	}
	mqttClient := mqtt.NewMQTTClient(cfg.MQTTBroker, "notification-service", 1, cfg.MQTTSecure)

	svc := service.NewNotificationService(cfg, eventBusConsumer, mqttClient)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go svc.StartListening(ctx)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt, syscall.SIGTERM)
	<-sigs
	cancel()

	done := make(chan struct{})
	go func() {
		_ = eventBusConsumer.Close()
		mqttClient.Close()
		close(done)
	}()

	select {
	case <-done:
	case <-time.After(10 * time.Second):
		log.Println("timeout waiting for shutdown")
	}
}
