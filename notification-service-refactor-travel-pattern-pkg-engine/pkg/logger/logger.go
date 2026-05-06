package logger

import (
	_ "github.com/PlatformCore/libpackage/observability/logging"
	"log"
)

func Info(msg string, args ...any)  { log.Printf("[notification] "+msg, args...) }
func Error(msg string, args ...any) { log.Printf("[notification][error] "+msg, args...) }
