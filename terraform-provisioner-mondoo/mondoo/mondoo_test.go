package mondoo

import (
	"testing"

	"github.com/hashicorp/terraform/config"
	"github.com/hashicorp/terraform/terraform"
)

func resourceConfig(t *testing.T, c map[string]interface{}) *terraform.ResourceConfig {
	r, err := config.NewRawConfig(c)
	if err != nil {
		t.Fatalf("config error: %s", err)
	}
	return terraform.NewResourceConfig(r)
}

func TestProvisionerValidateOK(t *testing.T) {
	c := resourceConfig(t, map[string]interface{}{
		"reporter": map[string]interface{}{
			"format": "yaml",
		},
	})

	warn, errs := Provisioner().Validate(c)
	if len(warn) > 0 {
		t.Fatalf("Warnings: %v", warn)
	}
	if len(errs) > 0 {
		t.Fatalf("Errors: %v", errs)
	}
}
