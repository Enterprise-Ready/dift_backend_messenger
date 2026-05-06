package health

import (
	_ "github.com/PlatformCore/libpackage/observability/healthcheck"
	"time"
)

type Status struct {
	Service string `json:"service"`
	Version string `json:"version"`
	Status  string `json:"status"`
	Time    string `json:"time"`
}

func Live(service, version string) Status {
	return Status{service, version, "live", time.Now().UTC().Format(time.RFC3339)}
}
func Ready(service, version string) Status {
	return Status{service, version, "ready", time.Now().UTC().Format(time.RFC3339)}
}
