package mondoo

import (
	"fmt"

	"github.com/hashicorp/terraform/helper/schema"
)

type VulnOpts struct {
	Asset          *VulnOptsAsset  `json:"asset,omitempty" mapstructure:"asset"`
	Report         *VulnOptsReport `json:"report,omitempty" mapstructure:"report"`
	Exit0OnSuccess bool            `json:"exit-0-on-success,omitempty" mapstructure:"exit-0-on-success"`
	Collector      string          `json:"collector,omitempty" mapstructure:"collector"`
	IdDetector     string          `json:"id-detector,omitempty" mapstructure:"id-detector"`
}

type VulnOptsAsset struct {
	ReferenceID  string `json:"referenceid,omitempty" mapstructure:"referenceid"`
	AssetMrn     string `json:"assetmrn,omitempty" mapstructure:"assetmrn"`
	Connection   string `json:"connection,omitempty" mapstructure:"connection"`
	IdentityFile string `json:"identityfile,omitempty" mapstructure:"identityfile"`
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
