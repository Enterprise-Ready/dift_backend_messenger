package adminclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	_ "github.com/PlatformCore/libpackage/clients/http"
	"net/http"
	"strings"
	"time"
)

type Client struct {
	baseURL    string
	token      string
	httpClient *http.Client
}

func New(baseURL, token string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 4 * time.Second
	}
	return &Client{strings.TrimRight(baseURL, "/"), token, &http.Client{Timeout: timeout}}
}
func (c *Client) Enabled() bool { return c != nil && c.baseURL != "" }
func (c *Client) ReportDelivery(ctx context.Context, payload map[string]any) error {
	if !c.Enabled() {
		return nil
	}
	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/api/v1/admin/notifications/delivery-status", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return fmt.Errorf("admin service status %d", resp.StatusCode)
	}
	return nil
}
