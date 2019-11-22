package mondoo

import (
	"fmt"

	"github.com/hashicorp/terraform/helper/schema"
)

type VulnOpts struct {
	Assets         []*VulnOptsAsset `json:"assets,omitempty" mapstructure:"assets"`
	Report         *VulnOptsReport  `json:"report,omitempty" mapstructure:"report"`
	Exit0OnSuccess bool             `json:"exit-0-on-success,omitempty" mapstructure:"exit-0-on-success"`
	Collector      string           `json:"collector,omitempty" mapstructure:"collector"`
	Async          bool             `json:"async,omitempty" mapstructure:"async"`
	IdDetector     string           `json:"id-detector,omitempty" mapstructure:"id-detector"`
}

type VulnOptsAsset struct {
	ReferenceID  string            `json:"referenceid,omitempty" mapstructure:"referenceid"`
	AssetMrn     string            `json:"assetmrn,omitempty" mapstructure:"assetmrn"`
	Connection   string            `json:"connection,omitempty" mapstructure:"connection"`
	IdentityFile string            `json:"identityfile,omitempty" mapstructure:"identityfile"`
	Password     string            `json:"password,omitempty" mapstructure:"password"`
	Labels       map[string]string `json:"labels,omitempty" mapstructure:"labels"`
}

type VulnOptsReport struct {
	Format string `json:"format,omitempty"`
}

// read the report config
func tfReportConfig(data *schema.ResourceData) *VulnOptsReport {
	reportData := StringMap(data.Get("report"))

	conf := &VulnOptsReport{
		Format: StringValue(reportData, "format"),
	}
	return conf
}

func tfCollector(data *schema.ResourceData) string {
	collector, ok := data.Get("collector").(string)
	if !ok {
		return ""
	}
	return collector
}

func StringValue(keymap map[string]interface{}, key string) string {
	v, ok := keymap[key]
	if ok {
		switch v := v.(type) {
		case string:
			return v
		default:
			panic(fmt.Sprintf("unsupported type: %T", v))
		}
	}

	return ""
}

func StringMap(v interface{}) map[string]interface{} {
	switch v := v.(type) {
	case nil:
		return make(map[string]interface{})
	case map[string]interface{}:
		return v
	default:
		panic(fmt.Sprintf("unsupported type: %T", v))
	}
}
