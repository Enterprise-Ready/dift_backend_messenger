package notificationengine

import (
	_ "github.com/PlatformCore/libpackage/resilience/backpressure"
	_ "github.com/PlatformCore/libpackage/resilience/circuitbreaker"
	"strings"
)

type RouteDecision struct {
	Channels  []string
	Priority  string
	TopicHint string
}

func Decide(channels []string, priority string, recipientTopic string, defaults []string) RouteDecision {
	out := make([]string, 0, len(channels)+len(defaults))
	seen := map[string]struct{}{}
	src := channels
	if len(src) == 0 {
		src = defaults
	}
	for _, c := range src {
		c = strings.TrimSpace(strings.ToLower(c))
		if c == "" {
			continue
		}
		if _, ok := seen[c]; ok {
			continue
		}
		seen[c] = struct{}{}
		out = append(out, c)
	}
	if len(out) == 0 {
		out = []string{"mqtt"}
	}
	if strings.TrimSpace(priority) == "" {
		priority = "normal"
	}
	return RouteDecision{out, priority, recipientTopic}
}
