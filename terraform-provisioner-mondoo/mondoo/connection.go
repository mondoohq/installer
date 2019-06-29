package mondoo

import (
	"errors"
	"fmt"

	"github.com/hashicorp/terraform/communicator/shared"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/mapstructure"
)

// see https://www.terraform.io/docs/provisioners/connection.html
type ProvisionerConnection struct {
	Type       string `mapstructure:"type"`
	User       string `mapstructure:"user"`
	Password   string `mapstructure:"password"`
	PrivateKey string `mapstructure:"private_key"`
	Host       string `mapstructure:"host"`
	Port       int    `mapstructure:"port"`
}

func (p *ProvisionerConnection) ToMondooConnection() (string, error) {
	switch p.Type {
	case "ssh":
		return fmt.Sprintf("ssh://%s@%s", p.User, p.Host), nil
	case "local":
		return "local://", nil
	}

	return "", errors.New(fmt.Sprintf("the requested %s connection type is not supported by mondoo terraform provisioner", p.Type))
}

func tfConnection(s *terraform.InstanceState) (*ProvisionerConnection, error) {
	connInfo := &ProvisionerConnection{}
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
