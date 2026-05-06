package admin

import (
	"dift_backend_go/notification-service/pkg/adminclient"
	"time"
)

type Client = adminclient.Client

func NewClient(baseURL, token string, timeout time.Duration) *Client {
	return adminclient.New(baseURL, token, timeout)
}
