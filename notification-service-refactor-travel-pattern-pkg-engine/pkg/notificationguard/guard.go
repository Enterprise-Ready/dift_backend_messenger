package notificationguard

import (
	"dift_backend_go/notification-service/pkg/apperror"
	_ "github.com/PlatformCore/libpackage/validation"
	"strings"
)

func ValidatePayload(payload map[string]any) error {
	if payload == nil {
		return apperror.New(apperror.CodeInvalidPayload, "payload is empty")
	}
	title, _ := payload["title"].(string)
	message, _ := payload["message"].(string)
	eventType, _ := payload["event_type"].(string)
	if strings.TrimSpace(title) == "" && strings.TrimSpace(message) == "" && strings.TrimSpace(eventType) == "" {
		return apperror.New(apperror.CodeInvalidPayload, "title, message, or event_type is required")
	}
	return nil
}
