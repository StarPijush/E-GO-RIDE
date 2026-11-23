package validation

import (
	"net/http/httptest"
	"strings"
	"testing"
)

func TestDecodeJSONRejectsUnknownFieldsAndTrailingValues(t *testing.T) {
	type payload struct {
		Name string `json:"name"`
	}
	for _, body := range []string{`{"name":"ok","role":"admin"}`, `{"name":"ok"}{"name":"again"}`} {
		req := httptest.NewRequest("POST", "/", strings.NewReader(body))
		var value payload
		if err := DecodeJSON(req, &value); err == nil {
			t.Errorf("expected body %q to be rejected", body)
		}
	}
}

func TestDecodeJSONAcceptsOneValidObject(t *testing.T) {
	type payload struct {
		Name string `json:"name"`
	}
	req := httptest.NewRequest("POST", "/", strings.NewReader(`{"name":"valid"}`))
	var value payload
	if err := DecodeJSON(req, &value); err != nil || value.Name != "valid" {
		t.Fatalf("expected valid JSON, got value %#v and error %v", value, err)
	}
}
