package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"dift_backend_go/notification-service/config"
	"dift_backend_go/notification-service/internal/app"
)

func main() {
	cfg := config.LoadConfig()
	application, err := app.Bootstrap(cfg)
	if err != nil {
		log.Fatalf("bootstrap failed: %v", err)
	}

	serverErr := make(chan error, 1)
	go func() {
		log.Printf("[notification-service] http listening on %s", application.HTTPServer.Addr)
		serverErr <- application.Start(context.Background())
	}()

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt, syscall.SIGTERM)

	select {
	case sig := <-sigs:
		log.Printf("shutdown signal received: %s", sig.String())
	case err := <-serverErr:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Printf("server error: %v", err)
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = application.Shutdown(ctx)
}
