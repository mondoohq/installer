package mondoo

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func validateFn(c *terraform.ResourceConfig) (ws []string, es []error) {
	return nil, nil
}

func applyFn(ctx context.Context) error {
	s := ctx.Value(schema.ProvRawStateKey).(*terraform.InstanceState)
	data := ctx.Value(schema.ProvConfigDataKey).(*schema.ResourceData)
	o := ctx.Value(schema.ProvOutputKey).(terraform.UIOutput)

	// read ssh connection information
	sshConfig, err := tfConnInfo(s)
	if err != nil {
		return err
	}

	// build mondoo config
	conf := &VulnOpts{
		Asset: &VulnOptsAsset{
			Connection: fmt.Sprintf("ssh://%s@%s", sshConfig.User, sshConfig.Host),
		},
		Report: tfReportConfig(data),
	}

	// run mondoo vuln command
	return run(ctx, s, data, o, conf)
}

func Provisioner() terraform.ResourceProvisioner {
	return &schema.Provisioner{
		Schema: map[string]*schema.Schema{
			"reporter": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"format": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
					},
				},
			},
		},
		ApplyFunc:    applyFn,
		ValidateFunc: validateFn,
	}
}
