package httpadapter

import (
	"net/http"

	_ "github.com/PlatformCore/libpackage/middleware/backpressure"
	_ "github.com/PlatformCore/libpackage/middleware/core"
	_ "github.com/PlatformCore/libpackage/middleware/logging"
	_ "github.com/PlatformCore/libpackage/middleware/metrics"
	_ "github.com/PlatformCore/libpackage/middleware/recovery"
	_ "github.com/PlatformCore/libpackage/middleware/requestid"
	_ "github.com/PlatformCore/libpackage/middleware/securityheaders"
	_ "github.com/PlatformCore/libpackage/middleware/timeout"
	_ "github.com/PlatformCore/libpackage/middleware/tracing"
)

func WithStandardMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		next.ServeHTTP(w, r)
	})
}
