package service

import (
	"context"
	"encoding/json"
	"log"
	"strings"
	"time"

	"dift_backend_go/notification-service/config"
	"dift_backend_go/notification-service/internal/integration/event"
	mqtt "dift_backend_go/notification-service/internal/integration/mqtt_client"
)

type DriverGeneralNotificationService struct {
	cfg         *config.Config
	eventClient event.Client
	mqttClient  mqtt.Client
}

type GeneralNotification struct {
	ID        string         `json:"id,omitempty"`
	Title     string         `json:"title"`
	Body      string         `json:"body"`
	Category  string         `json:"category,omitempty"`
	Severity  string         `json:"severity,omitempty"`
	Audience  string         `json:"audience,omitempty"`
	DriverID  string         `json:"driver_id,omitempty"`
	RouteID   string         `json:"route_id,omitempty"`
	Action    string         `json:"action,omitempty"`
	Topic     string         `json:"topic,omitempty"`
	Data      map[string]any `json:"data,omitempty"`
	Timestamp int64          `json:"timestamp"`
}

func NewNotificationService(
	cfg *config.Config,
	eventClient event.Client,
	mqttClient mqtt.Client,
) *DriverGeneralNotificationService {
	return &DriverGeneralNotificationService{
		cfg:         cfg,
		eventClient: eventClient,
		mqttClient:  mqttClient,
	}
}

func (s *DriverGeneralNotificationService) StartListening(ctx context.Context) {
	if strings.TrimSpace(s.cfg.EventBusDriverGeneralTopic) != "" {
		log.Printf("[DriverGeneralNotificationService] listening topic=%s", s.cfg.EventBusDriverGeneralTopic)
		s.eventClient.Subscribe(ctx, s.cfg.EventBusDriverGeneralTopic, s.handleDriverGeneralEvent)
	}
	if strings.TrimSpace(s.cfg.EventBusGeneralTopic) != "" {
		log.Printf("[DriverGeneralNotificationService] listening topic=%s", s.cfg.EventBusGeneralTopic)
		s.eventClient.Subscribe(ctx, s.cfg.EventBusGeneralTopic, s.handleGeneralEvent)
	}
}

func (s *DriverGeneralNotificationService) handleDriverGeneralEvent(raw []byte) {
	s.dispatch(raw, s.cfg.MQTTTopicDriver)
}

func (s *DriverGeneralNotificationService) handleGeneralEvent(raw []byte) {
	s.dispatch(raw, s.cfg.MQTTTopicGeneral)
}

func (s *DriverGeneralNotificationService) dispatch(raw []byte, fallbackTopic string) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	payload, topic, err := normalizeNotification(raw, fallbackTopic)
	if err != nil {
		log.Printf("[DriverGeneralNotificationService] invalid notification payload: %v", err)
		return
	}
	if err := s.mqttClient.SendRaw(ctx, topic, payload); err != nil {
		log.Printf("[DriverGeneralNotificationService] mqtt publish failed topic=%s err=%v", topic, err)
	}
}

func normalizeNotification(raw []byte, fallbackTopic string) ([]byte, string, error) {
	var payload GeneralNotification
	if err := json.Unmarshal(raw, &payload); err != nil {
		return nil, "", err
	}
	if payload.Timestamp == 0 {
		payload.Timestamp = time.Now().Unix()
	}
	if strings.TrimSpace(payload.Audience) == "" {
		payload.Audience = "driver"
	}
	topic := fallbackTopic
	if strings.TrimSpace(payload.Topic) != "" {
		topic = strings.TrimSpace(payload.Topic)
	}
	normalized, err := json.Marshal(payload)
	if err != nil {
		return nil, "", err
	}
	return normalized, topic, nil
}
