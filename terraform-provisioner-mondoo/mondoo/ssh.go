package mondoo

import (
	"github.com/hashicorp/terraform/communicator/shared"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/mapstructure"
)

type sshConnInfo struct {
	User       string
	Password   string
	PrivateKey string `mapstructure:"private_key"`
	Host       string
	Port       int
}

func tfConnInfo(s *terraform.InstanceState) (*sshConnInfo, error) {
	connInfo := &sshConnInfo{}
	decConf := &mapstructure.DecoderConfig{
		WeaklyTypedInput: true,
		Result:           connInfo,
	}
	dec, err := mapstructure.NewDecoder(decConf)
	if err != nil {
		return nil, err
	}
	if err := dec.Decode(s.Ephemeral.ConnInfo); err != nil {
		return nil, err
	}

	// format the host if needed, needed for IPv6
	connInfo.Host = shared.IpFormat(connInfo.Host)
	return connInfo, nil
}
