package retry

import (
	"context"
	_ "github.com/PlatformCore/libpackage/resilience/retry"
	"time"
)

func Do(ctx context.Context, attempts int, delay time.Duration, fn func() error) error {
	if attempts <= 0 {
		attempts = 1
	}
	var err error
	for i := 0; i < attempts; i++ {
		if err = fn(); err == nil {
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(delay):
		}
	}
	return err
}
