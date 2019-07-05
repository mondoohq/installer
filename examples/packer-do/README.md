# Build an Dropt with Packer & Mondoo Vulnerability Scan

## Preconditions

 * [DigitalOcean Account](https://www.digitalocean.com/)
 * [Packer CLI installed on workstation](https://www.packer.io/intro/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.io/docs/agent/installation)
 * [Mondoo Packer Provisioner](https://mondoo.io/docs/apps/packer)


 ## Build your image

Verify the packer configuration:

```
$ packer validate example.json
Template validated successfully.
```

Set DIGITALOCEAN_TOKEN as environment variable:

```
export DIGITALOCEAN_TOKEN=MYTOKEN
```

Run packer build:

```
$ packer build example.json
packer build example.json                                                                 
digitalocean output will be in this color.

==> digitalocean: Creating temporary ssh key for droplet...
==> digitalocean: Creating droplet...
==> digitalocean: Waiting for droplet to become active...
==> digitalocean: Using ssh communicator to connect: 67.207.88.195
==> digitalocean: Waiting for SSH to become available...
==> digitalocean: Connected to SSH!
==> digitalocean: Running mondoo vulnerability scan...
==> digitalocean: Executing Mondoo: [mondoo vuln]
    digitalocean: Start vulnerability scan:
  →  detected automated runtime environment: Packer
    digitalocean: 5:32PM INF ssh uses scp (beta) instead of sftp for file transfer transport=ssh
  →  verify platform access to ssh://chartmann@127.0.0.1:58186
  →  gather platform details................................................................
  →  detected ubuntu 18.04
  →  gather platform packages for vulnerability scan.................................................................................................
  →  found 507 packages
    digitalocean:   →  analyse packages for vulnerabilities
    digitalocean: Advisory Report:
    digitalocean:   ■        PACKAGE          INSTALLED            VULNERABLE (<)  ADVISORY
    digitalocean:   ■   7.8  bash-completion  1:2.8-1ubuntu1                       https://mondoo.app/advisories/
    digitalocean:   ■   7.5  patch            2.7.6-2ubuntu1                       https://mondoo.app/advisories/
    digitalocean:   ■   6.5  libxdmcp6        1:1.1.2-3                            https://mondoo.app/advisories/
    digitalocean:   ■   5.9  libgcrypt20      1.8.1-4ubuntu1.1                     https://mondoo.app/advisories/
    digitalocean:   ■   5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
    digitalocean:   ├─  5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
    digitalocean:   ├─  5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
    digitalocean:   ╰─  0    cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
    digitalocean:   ■   5.5  tcpdump          4.9.2-3                              https://mondoo.app/advisories/
    digitalocean:   ╰─  0    tcpdump          4.9.2-3                              https://mondoo.app/advisories/
    digitalocean:   ■   3.3  xdg-user-dirs    0.17-1ubuntu1                        https://mondoo.app/advisories/
    digitalocean:   ■   0    bsdmainutils     11.1.2ubuntu1                        https://mondoo.app/advisories/
    digitalocean:   ■   0    byobu            5.125-0ubuntu1                       https://mondoo.app/advisories/
    digitalocean:   ■   0    coreutils        8.28-1ubuntu1                        https://mondoo.app/advisories/
    digitalocean:   ╰─  0    coreutils        8.28-1ubuntu1                        https://mondoo.app/advisories/
    digitalocean:   ■   0    liblzo2-2        2.08-1.2                             https://mondoo.app/advisories/
    digitalocean:   ■   0    rsync            3.1.2-2.1ubuntu1                     https://mondoo.app/advisories/
  →  ■ found 17 advisories: 0 critical, 2 high, 6 medium, 1 low, 8 none, 0 unknown
  →  report is available at https://mondoo.app/v/serene-dhawan-599345/focused-darwin-833545/reports/1NbDF3cN1u83oX60HDtFyWiU3EE
==> digitalocean: Destroying droplet...
==> digitalocean: Deleting temporary ssh key...
Build 'digitalocean' errored: Error executing Mondoo: Non-zero exit status: exit status 103
```

At the end of the packer build, Packer outputs the mondoo assessment and the artifacts. The report is stored for future reference. 