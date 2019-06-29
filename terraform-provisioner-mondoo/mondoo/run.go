package mondoo

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/armon/circbuf"
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
	linereader "github.com/mitchellh/go-linereader"
)

const (
	// maxBufSize limits how much output we collect from a local
	// invocation. This is to prevent TF memory usage from growing
	// to an enormous amount due to a faulty process.
	maxBufSize = 8 * 1024
)

func run(
	ctx context.Context,
	s *terraform.InstanceState,
	data *schema.ResourceData,
	o terraform.UIOutput,
	conf *VulnOpts,
) error {
	// prep config for mondoo executable
	mondooScanConf, err := json.Marshal(conf)
	if err != nil {
		return err
	}

	cmdbin := "mondoo"
	cmdargs := []string{"vuln"}

	// we use os.Pipe instead of goroutines, see golang.org/issue/18874
	pr, pw, err := os.Pipe()
	if err != nil {
		return fmt.Errorf("failed to initialize pipe for output: %s", err)
	}

	// setup the mondoo command
	cmd := exec.Command(cmdbin, cmdargs...)
	cmd.Stderr = pw
	cmd.Stdout = pw

	// set environment variable for mondod executable to detect that we are in
	// terraform mode
	cmd.Env = os.Environ()
	cmd.Env = append(cmd.Env, "CI=true")
	cmd.Env = append(cmd.Env, "TERRAFORM_PIPELINE=true")

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	stdin.Write(mondooScanConf)
	stdin.Close()

	output, _ := circbuf.NewBuffer(maxBufSize)

	// copy cmd output to tf output
	tee := io.TeeReader(pr, output)

	// copy the tee channel to terraform UI output
	copyDoneCh := make(chan struct{})
	go copyOutputChan(o, tee, copyDoneCh)

	// output that we kick off the scan
	o.Output(fmt.Sprintf("Executing: %s", strings.Join(cmdargs, " ")))

	// start the command
	err = cmd.Start()
	if err == nil {
		err = cmd.Wait()
	}

	pw.Close()

	// Cancelling the command may block the pipe reader if the file descriptor
	// was passed to a child process which hasn't closed it. In this case the
	// copyOutput goroutine will just hang out until exit.
	select {
	case <-copyDoneCh:
	case <-ctx.Done():
	}

	if err != nil {
		return fmt.Errorf("Error running command '%s': %v. Output: %s",
			strings.Join(cmdargs, " "), err, output.Bytes())
	}

	return nil
}

func copyOutputChan(o terraform.UIOutput, r io.Reader, doneCh chan<- struct{}) {
	defer close(doneCh)
	lr := linereader.New(r)
	for line := range lr.Ch {
		o.Output(line)
	}
}
