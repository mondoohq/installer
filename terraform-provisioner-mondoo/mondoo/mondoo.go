package mondoo

import (
	"context"

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

	o.Output("start mondoo provisioner")

	// read ssh connection information
	connInfo, err := tfConnection(s)
	if err != nil {
		return err
	}

	// convert tf connection to mondoo connection string
	mondooConn, err := connInfo.ToMondooConnection()
	if err != nil {
		return err
	}

	// build mondoo config
	conf := &VulnOpts{
		Asset: &VulnOptsAsset{
			Connection: mondooConn,
		},
		Report:    tfReportConfig(data),
		Collector: tfCollector(data),
	}

	// run mondoo vuln command
	return run(ctx, s, data, o, conf)
}

func Provisioner() terraform.ResourceProvisioner {
	return &schema.Provisioner{
		Schema: map[string]*schema.Schema{
			"collector": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
			"report": &schema.Schema{
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
