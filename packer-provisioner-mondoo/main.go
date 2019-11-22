package main

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"os/user"
	"strconv"
	"strings"
	"sync"
	"unicode"

	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"io/ioutil"

	"golang.org/x/crypto/ssh"

	"github.com/hashicorp/packer/common"
	"github.com/hashicorp/packer/common/adapter"
	"github.com/hashicorp/packer/helper/config"
	"github.com/hashicorp/packer/packer"
	"github.com/hashicorp/packer/packer/plugin"
	"github.com/hashicorp/packer/packer/tmp"
	"github.com/hashicorp/packer/template/interpolate"
)

type Config struct {
	common.PackerConfig  `mapstructure:",squash"`
	Command              string // The command to run mondoo
	ctx                  interpolate.Context
	HostAlias            string `mapstructure:"host_alias"`
	User                 string `mapstructure:"user"`
	LocalPort            uint   `mapstructure:"local_port"`
	SSHHostKeyFile       string `mapstructure:"ssh_host_key_file"`
	SSHAuthorizedKeyFile string `mapstructure:"ssh_authorized_key_file"`
	// packer's SFTP proxy is not reliable on some unix/linux systems,
	// therefore we recommend to use scp as default for packer proxy
	UseSFTP       bool              `mapstructure:"use_sftp"`
	Debug         bool              `mapstructure:"debug"`
	MondooEnvVars []string          `mapstructure:"mondoo_env_vars"`
	OnFailure     string            `mapstructure:"on_failure"`
	Labels        map[string]string `mapstructure:"labels"`

	// WinRM
	WinRMUser     string `mapstructure:"winrm_user"`
	WinRMPassword string `mapstructure:"winrm_password"`
}

type Provisioner struct {
	config  Config
	adapter *adapter.Adapter
	done    chan struct{}
}

func (p *Provisioner) Prepare(raws ...interface{}) error {
	p.done = make(chan struct{})

	err := config.Decode(&p.config, &config.DecodeOpts{
		Interpolate:        true,
		InterpolateContext: &p.config.ctx,
		InterpolateFilter: &interpolate.RenderFilter{
			Exclude: []string{},
		},
	}, raws...)
	if err != nil {
		return err
	}

	if p.config.Command == "" {
		p.config.Command = "mondoo"
	}

	var errs *packer.MultiError
	if len(p.config.SSHAuthorizedKeyFile) > 0 {
		err = validateFileConfig(p.config.SSHAuthorizedKeyFile, "ssh_authorized_key_file", true)
		if err != nil {
			log.Println(p.config.SSHAuthorizedKeyFile, "does not exist")
			errs = packer.MultiErrorAppend(errs, err)
		}
	}

	// ensure that we disable ssh auth, since the packer proxy only allows one auth mechanism
	p.config.MondooEnvVars = append(p.config.MondooEnvVars, "SSH_AUTH_SOCK=")

	if !p.config.UseSFTP {
		p.config.MondooEnvVars = append(p.config.MondooEnvVars, "MONDOO_SSH_SCP=on")
	}

	if p.config.Debug {
		p.config.MondooEnvVars = append(p.config.MondooEnvVars, "DEBUG=1")
	}

	if p.config.LocalPort > 65535 {
		errs = packer.MultiErrorAppend(errs, fmt.Errorf("local_port: %d must be a valid port", p.config.LocalPort))
	}

	if p.config.User == "" {
		usr, err := user.Current()
		if err != nil {
			errs = packer.MultiErrorAppend(errs, err)
		} else {
			p.config.User = usr.Username
		}
	}
	if p.config.User == "" {
		errs = packer.MultiErrorAppend(errs, fmt.Errorf("user: could not determine current user from environment."))
	}

	if errs != nil && len(errs.Errors) > 0 {
		return errs
	}

	return nil
}

func (p *Provisioner) Provision(ctx context.Context, ui packer.Ui, comm packer.Communicator) error {
	ui.Say("Running mondoo vulnerability scan...")

	k, err := newUserKey(p.config.SSHAuthorizedKeyFile)
	if err != nil {
		return err
	}

	hostSigner, err := newSigner(p.config.SSHHostKeyFile)
	// Remove the private key file
	if len(k.privKeyFile) > 0 {
		defer os.Remove(k.privKeyFile)
	}

	keyChecker := ssh.CertChecker{
		UserKeyFallback: func(conn ssh.ConnMetadata, pubKey ssh.PublicKey) (*ssh.Permissions, error) {
			if user := conn.User(); user != p.config.User {
				return nil, errors.New(fmt.Sprintf("authentication failed: %s is not a valid user", user))
			}

			if !bytes.Equal(k.Marshal(), pubKey.Marshal()) {
				return nil, errors.New("authentication failed: unauthorized key")
			}

			return nil, nil
		},
	}

	config := &ssh.ServerConfig{
		AuthLogCallback: func(conn ssh.ConnMetadata, method string, err error) {
			log.Printf("authentication attempt from %s to %s as %s using %s", conn.RemoteAddr(), conn.LocalAddr(), conn.User(), method)
		},
		PublicKeyCallback: keyChecker.Authenticate,
	}

	config.AddHostKey(hostSigner)

	localListener, err := func() (net.Listener, error) {

		port := p.config.LocalPort
		tries := 1
		if port != 0 {
			tries = 10
		}
		for i := 0; i < tries; i++ {
			l, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
			port++
			if err != nil {
				ui.Say(err.Error())
				continue
			}
			_, portStr, err := net.SplitHostPort(l.Addr().String())
			if err != nil {
				ui.Say(err.Error())
				continue
			}
			portUint64, err := strconv.ParseUint(portStr, 10, 0)
			if err != nil {
				ui.Say(err.Error())
				continue
			}
			p.config.LocalPort = uint(portUint64)
			return l, nil
		}
		return nil, errors.New("Error setting up SSH proxy connection")
	}()

	if err != nil {
		return err
	}

	ui = &packer.SafeUi{
		Sem: make(chan int, 1),
		Ui:  ui,
	}

	// initialize ssh adapter
	p.adapter = adapter.NewAdapter(p.done, localListener, config, "sftp -e", ui, comm)

	defer func() {
		log.Print("shutting down the SSH proxy")
		close(p.done)
		p.adapter.Shutdown()
	}()

	go p.adapter.Serve()

	if err := p.executeMondoo(ctx, ui, comm, k.privKeyFile); err != nil {
		return fmt.Errorf("Error executing Mondoo: %s", err)
	}

	return nil
}

// Cancel just exists when provision is cancelled
func (p *Provisioner) Cancel() {
	if p.done != nil {
		close(p.done)
	}
	if p.adapter != nil {
		p.adapter.Shutdown()
	}
	os.Exit(0)
}

func (p *Provisioner) executeMondoo(ctx context.Context, ui packer.Ui, comm packer.Communicator, privKeyFile string) error {
	var envvars []string

	if len(p.config.MondooEnvVars) > 0 {
		envvars = append(envvars, p.config.MondooEnvVars...)
	}

	// Always available Packer provided env vars
	p.config.MondooEnvVars = append(p.config.MondooEnvVars, fmt.Sprintf("PACKER_BUILD_NAME=%s", p.config.PackerBuildName))
	p.config.MondooEnvVars = append(p.config.MondooEnvVars, fmt.Sprintf("PACKER_BUILDER_TYPE=%s", p.config.PackerBuilderType))

	args := []string{"scan"}
	conntype := "ssh"
	// TODO: allow overwrite of host
	host := "127.0.0.1"
	password := ""
	endpoint := fmt.Sprintf("%s:%d", host, p.config.LocalPort)

	if len(p.config.WinRMUser) > 0 {
		conntype = "winrm"
		p.config.User = p.config.WinRMUser
		password = p.config.WinRMPassword
		privKeyFile = ""

		// we need to get the ip from packer
		// see https://github.com/hashicorp/packer/issues/7079
		getip := "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne 'Disconnected'}).IPv4Address.IPAddress"
		var b bytes.Buffer
		stdout := bufio.NewWriter(&b)
		cmd := &packer.RemoteCmd{
			Command: fmt.Sprintf(`powershell -c "%s"`, getip),
			Stdout:  stdout,
		}
		cmd.RunWithUi(ctx, comm, ui)
		stdout.Flush()
		if cmd.ExitStatus() == 0 {
			endpoint = strings.TrimSpace(string(b.Bytes()))
		} else {
			return fmt.Errorf("could not gather ip for winrm. please set host via config")
		}
	}

	conf := &VulnOpts{
		Assets: []*VulnOptsAsset{
			&VulnOptsAsset{
				Connection:   fmt.Sprintf("%s://%s@%s", conntype, p.config.User, endpoint),
				IdentityFile: privKeyFile,
				Password:     password,
				Labels:       p.config.Labels,
			},
		},
		Report: &VulnOptsReport{
			Format: "cli",
		},
	}

	// pass packer build, even if the scan identified vulnerabilities
	if p.config.OnFailure == "continue" {
		conf.Exit0OnSuccess = true
	}

	// prep config for mondoo executable
	mondooScanConf, err := json.Marshal(conf)
	if err != nil {
		return err
	}

	if p.config.Debug {
		ui.Say(fmt.Sprintf("mondoo configuration: %v", string(mondooScanConf)))
	}

	cmd := exec.Command(p.config.Command, args...)

	cmd.Env = os.Environ()
	if len(envvars) > 0 {
		cmd.Env = append(cmd.Env, envvars...)
	}
	cmd.Env = append(cmd.Env, "CI=true")
	cmd.Env = append(cmd.Env, "PACKER_PIPELINE=true")

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	stdin.Write(mondooScanConf)
	stdin.Close()

	wg := sync.WaitGroup{}
	repeat := func(r io.ReadCloser) {
		reader := bufio.NewReader(r)
		for {
			line, err := reader.ReadString('\n')
			if line != "" {
				line = strings.TrimRightFunc(line, unicode.IsSpace)
				ui.Message(line)
			}
			if err != nil {
				if err == io.EOF {
					break
				} else {
					ui.Error(err.Error())
					break
				}
			}
		}
		wg.Done()
	}
	wg.Add(2)
	go repeat(stdout)
	go repeat(stderr)

	ui.Say(fmt.Sprintf("Executing Mondoo: %s", cmd.Args))
	if err := cmd.Start(); err != nil {
		return err
	}
	wg.Wait()
	err = cmd.Wait()

	if err != nil {
		return fmt.Errorf("Non-zero exit status: %s", err)
	}

	return nil
}

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

func main() {
	server, err := plugin.Server()
	if err != nil {
		panic(err)
	}
	server.RegisterProvisioner(new(Provisioner))
	server.Serve()
}

func validateFileConfig(name string, config string, req bool) error {
	if req {
		if name == "" {
			return fmt.Errorf("%s must be specified.", config)
		}
	}
	info, err := os.Stat(name)
	if err != nil {
		return fmt.Errorf("%s: %s is invalid: %s", config, name, err)
	} else if info.IsDir() {
		return fmt.Errorf("%s: %s must point to a file", config, name)
	}
	return nil
}

type userKey struct {
	ssh.PublicKey
	privKeyFile string
}

func newUserKey(pubKeyFile string) (*userKey, error) {
	userKey := new(userKey)
	if len(pubKeyFile) > 0 {
		pubKeyBytes, err := ioutil.ReadFile(pubKeyFile)
		if err != nil {
			return nil, errors.New("Failed to read public key")
		}
		userKey.PublicKey, _, _, _, err = ssh.ParseAuthorizedKey(pubKeyBytes)
		if err != nil {
			return nil, errors.New("Failed to parse authorized key")
		}

		return userKey, nil
	}

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, errors.New("Failed to generate key pair")
	}
	userKey.PublicKey, err = ssh.NewPublicKey(key.Public())
	if err != nil {
		return nil, errors.New("Failed to extract public key from generated key pair")
	}

	// To support mondoo calling back to us we need to write this file down
	privateKeyDer := x509.MarshalPKCS1PrivateKey(key)
	privateKeyBlock := pem.Block{
		Type:    "RSA PRIVATE KEY",
		Headers: nil,
		Bytes:   privateKeyDer,
	}
	tf, err := tmp.File("mondoo-key")
	if err != nil {
		return nil, errors.New("failed to create temp file for generated key")
	}
	_, err = tf.Write(pem.EncodeToMemory(&privateKeyBlock))
	if err != nil {
		return nil, errors.New("failed to write private key to temp file")
	}

	err = tf.Close()
	if err != nil {
		return nil, errors.New("failed to close private key temp file")
	}
	userKey.privKeyFile = tf.Name()

	return userKey, nil
}

type signer struct {
	ssh.Signer
}

func newSigner(privKeyFile string) (*signer, error) {
	signer := new(signer)

	if len(privKeyFile) > 0 {
		privateBytes, err := ioutil.ReadFile(privKeyFile)
		if err != nil {
			return nil, errors.New("Failed to load private host key")
		}

		signer.Signer, err = ssh.ParsePrivateKey(privateBytes)
		if err != nil {
			return nil, errors.New("Failed to parse private host key")
		}

		return signer, nil
	}

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, errors.New("Failed to generate server key pair")
	}

	signer.Signer, err = ssh.NewSignerFromKey(key)
	if err != nil {
		return nil, errors.New("Failed to extract private key from generated key pair")
	}

	return signer, nil
}
