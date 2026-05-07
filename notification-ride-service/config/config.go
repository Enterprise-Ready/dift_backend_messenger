package config

import (
	"log"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// Config holds application configuration for driver/general notification service.
type Config struct {
	HTTPPort int
	GRPCPort int
	Timeout  int

	EventBusBrokers            []string
	EventBusGroup              string
	EventBusDriverGeneralTopic string
	EventBusGeneralTopic       string

	MQTTBroker       string
	MQTTTopicDriver  string
	MQTTTopicGeneral string
	MQTTSecure       bool

	RedisURL                string
	RedisPassword           string
	RedisDB                 int
	RedisTTL                string
	RedisNotificationPrefix string
}

func LoadConfig() *Config {
	v := viper.New()
	v.SetConfigFile("./config/config.yaml")
	v.AutomaticEnv()

	if err := v.ReadInConfig(); err != nil {
		log.Printf("[Config] Warning reading config file, using defaults/env: %v", err)
	}

	cfg := &Config{
		HTTPPort:                   v.GetInt("server.http_port"),
		GRPCPort:                   v.GetInt("server.grpc_port"),
		Timeout:                    v.GetInt("server.timeout_ms"),
		EventBusBrokers:            v.GetStringSlice("event_bus.brokers"),
		EventBusGroup:              v.GetString("event_bus.group"),
		EventBusDriverGeneralTopic: v.GetString("event_bus.driver_general_topic"),
		EventBusGeneralTopic:       v.GetString("event_bus.general_topic"),
		MQTTBroker:                 v.GetString("mqtt.broker"),
		MQTTTopicDriver:            v.GetString("mqtt.driver_topic"),
		MQTTTopicGeneral:           v.GetString("mqtt.general_topic"),
		MQTTSecure:                 v.GetBool("mqtt.secure"),
		RedisURL:                   v.GetString("redis.url"),
		RedisPassword:              v.GetString("redis.password"),
		RedisDB:                    v.GetInt("redis.db"),
		RedisTTL:                   v.GetString("redis.ttl"),
		RedisNotificationPrefix:    v.GetString("redis.keys.notification_prefix"),
	}

	if cfg.HTTPPort == 0 {
		cfg.HTTPPort = 2222
	}
	if cfg.GRPCPort == 0 {
		cfg.GRPCPort = 5051
	}
	if cfg.EventBusGroup == "" {
		cfg.EventBusGroup = "notification-ride-service-group"
	}
	if cfg.EventBusDriverGeneralTopic == "" {
		cfg.EventBusDriverGeneralTopic = "driver.general.notifications"
	}
	if cfg.EventBusGeneralTopic == "" {
		cfg.EventBusGeneralTopic = "general.notifications"
	}
	if cfg.MQTTBroker == "" {
		cfg.MQTTBroker = "tcp://mqtt-broker:1883"
	}
	if cfg.MQTTTopicDriver == "" {
		cfg.MQTTTopicDriver = "ui/driver/general"
	}
	if cfg.MQTTTopicGeneral == "" {
		cfg.MQTTTopicGeneral = "ui/general/notification"
	}
	if cfg.RedisTTL == "" {
		cfg.RedisTTL = "30s"
	}
	if cfg.RedisNotificationPrefix == "" {
		cfg.RedisNotificationPrefix = "notification:"
	}
	if v := strings.TrimSpace(os.Getenv("MQTT_BROKER")); v != "" {
		cfg.MQTTBroker = v
	}
	if v := strings.TrimSpace(os.Getenv("DRIVER_GENERAL_NOTIFICATION_TOPIC")); v != "" {
		cfg.MQTTTopicDriver = v
	}
	if v := strings.TrimSpace(os.Getenv("GENERAL_NOTIFICATION_TOPIC")); v != "" {
		cfg.MQTTTopicGeneral = v
	}
	if v := strings.TrimSpace(os.Getenv("DRIVER_GENERAL_EVENT_TOPIC")); v != "" {
		cfg.EventBusDriverGeneralTopic = v
	}
	if v := strings.TrimSpace(os.Getenv("GENERAL_EVENT_TOPIC")); v != "" {
		cfg.EventBusGeneralTopic = v
	}

	log.Printf("[Config] Loaded configuration: %+v", cfg)
	return cfg
}
