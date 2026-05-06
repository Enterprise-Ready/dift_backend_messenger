# Notification Service Travel Pattern

This service follows the same structure used by the refactored travel/auth/routing services.

## Rules

- `internal/integration/*` is pure infrastructure/client/server code.
- `internal/adapter/inbound/*` receives external requests/messages and calls service logic.
- `internal/adapter/outbound/*` implements outbound persistence/gateway adapters.
- `internal/app/*` owns bootstrap and dependency wiring.
- `pkg/*` is the only place for service-specific direct engine usage.
- Middleware is imported directly from `github.com/PlatformCore/libpackage/middleware/...` and is not wrapped again inside the microservice.
- Legacy wrappers and servicecore were moved to `docs/legacy-*` with `legacy` build tags.

## Notification-specific changes

- MQTT is now generic notification delivery, not direct matching-service/driver-service coupling.
- Admin service integration is available through `admin_service.url` and reports delivery status when configured.
- Business metrics are available at `/metrics/business`.
- Health endpoints are available at `/health/live` and `/health/ready`.
