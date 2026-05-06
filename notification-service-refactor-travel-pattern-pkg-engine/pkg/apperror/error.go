package apperror

import (
	"fmt"
	_ "github.com/PlatformCore/libpackage/core/errors"
)

type Code string

const (
	CodeInvalidPayload     Code = "invalid_payload"
	CodeDeliveryFailed     Code = "delivery_failed"
	CodeUnsupportedChannel Code = "unsupported_channel"
)

type Error struct {
	Code    Code   `json:"code"`
	Message string `json:"message"`
	Cause   error  `json:"-"`
}

func (e *Error) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}
func New(code Code, msg string) *Error { return &Error{Code: code, Message: msg} }
func Wrap(code Code, msg string, cause error) *Error {
	return &Error{Code: code, Message: msg, Cause: cause}
}
