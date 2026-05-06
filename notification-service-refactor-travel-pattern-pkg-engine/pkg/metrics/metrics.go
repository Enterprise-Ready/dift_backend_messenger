package metrics

import (
	"encoding/json"
	_ "github.com/PlatformCore/libpackage/observability/metrics"
	"sync/atomic"
)

type Snapshot struct {
	DispatchedTotal uint64 `json:"dispatched_total"`
	FailedTotal     uint64 `json:"failed_total"`
	MQTTPublished   uint64 `json:"mqtt_published"`
	AdminReports    uint64 `json:"admin_reports"`
}

var dispatchedTotal, failedTotal, mqttPublished, adminReports atomic.Uint64

func RecordDispatched()    { dispatchedTotal.Add(1) }
func RecordFailed()        { failedTotal.Add(1) }
func RecordMQTTPublished() { mqttPublished.Add(1) }
func RecordAdminReport()   { adminReports.Add(1) }
func Current() Snapshot {
	return Snapshot{dispatchedTotal.Load(), failedTotal.Load(), mqttPublished.Load(), adminReports.Load()}
}
func JSON() []byte { b, _ := json.Marshal(Current()); return b }
