# Agent Registration

Every Mondoo agent needs to be registered to authenticate and authorize every request to Mondoo API. This ensures that all vulnerability data is securely transmitted.

# Retrieve Agent Credentials

Mondoo offers two ways to register agents:

1. Via registration token
2. Download agent credentials file

In most cases, the registration token is the best and easiest way to register a new agent. This approach has the advantage that it includes a secure way to transmit the credentials. If you need the agent credentials upfront (eg. for CI/CD environments), download agent credentials. Both options are available in our navigation pane:

![Navigation bar with agent credentials option](../../assets/mondoo-agents-credentials-download.png)

**Retrieve Mondoo agent registration token**

1. Open the Mondoo Dashboard
2. In the navigation pane, select the plus icon (+)
3. Copy the registration token

![Copy registration token](../../assets/mondoo-agents-registrationtoken.png)

**Retrieve Mondoo agent credentials**

1. Open the Mondoo Dashboard
2. In the navigation pane, select the download icon

This will download a JSON file which includes the agent private key. This approach is best for [CI/CD environments](../../integration/cicd/).

## Register Agent

Once you have a Mondoo registration token, you can use it to register the agent. The agent ships with a `mondoo register` command that eases the process to retrieve agent credentials securely.

The registration process registers the mondoo agent with Mondoo API so that you can see the agent in Mondoo's Dashboard. This approach ensures a secure and trusted communication. Data is always encrypted via HTTPS and payload is signed to ensure it is not been tampered with.

Then run `mondoo register --token 'PASTE_MONDOO_REGISTRATION_TOKEN'`. If the registration process was successful, the CLI prints the agent resource name.

```
mondoo register --token "eyJhbGci...6NSUwUn2DUzsppL696"

✔ agent //agents.api.mondoo.app/spaces/gallant-payne-155889/agents/1NmjgNKCoeD9SOz2UHNkT9IdcVc registered successfully
```

Via this process, the agent is retrieving all required configuration automatically.

## Configuration options

| Name | Description |
| -------------- | -----------------------------------|
| `api-endpoint`| The url of the Mondoo Cloud, `https://api.mondoo.app` is the default configuration
| `agentmrn`| Agent Mondoo Resource Name, identifies the agent
| `spacemrn`| Space Mondoo Resource Name, identifies the space that the agent belongs to
| `privatekey`| Agent's private key used to sign requests send to Mondoo API
| `certificate`| Agent's public certificate
| `collector`| Overwrite the collector endpoint. Supported values are 'https' urls and 'awssns' topics


```
api-endpoint: https://api.mondoo.app
agentmrn: //agents.api.mondoo.app/spaces/focused-darwin-833545/agents/1NairOj7L1Gi7BMQqPbBO4LAQ2v
spacemrn: //captain.api.mondoo.app/spaces/focused-darwin-833545
certificate: |
 -----BEGIN CERTIFICATE-----
 MIICWDCCAd2gAwIBAgIRALPRm8rb7Kujoo1oBFfSkQswCgYIKoZIzj0EAwMwQDE+
 MDwGA1UEChM1Ly9jYXB0YWluLmFwaS5tb25kb28uYXBwL3NwYWNlcy9mb2N1c2Vk
 LWRhcndpbi04MzM1NDUwHhcNMTkwNzA1MTEyMzI2WhcNMTkwNzA2MTEyMzI2WjBA
 MT4wPAYDVQQKEzUvL2NhcHRhaW4uYXBpLm1vbmRvby5hcHAvc3BhY2VzL2ZvY3Vz
 ZWQtZGFyd2luLTgzMzU0NTB2MBAGByqGSM49AgEGBSuBBAAiA2IABH/E7RKvq0Yo
 P209bAOyNV+phFB5NGO9454JmPK7Q+NSEz/EZppuvcMnK8KsN9okKx6H4rMLduwm
 zgK2yK42Uu6sA5yKk20dRJ3LXyQTfUZT+Wxp8HHP5GLqGMvkvBH87KOBmjCBlzAO
 BgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDAYDVR0TAQH/BAIw
 ADBiBgNVHREEWzBZglcvL2FnZW50cy5hcGkubW9uZG9vLmFwcC9zcGFjZXMvZm9j
 dXNlZC1kYXJ3aW4tODMzNTQ1L2FnZW50cy8xTmFpck9qN0wxR2k3Qk1RcVBiQk80
 TEFRMnYwCgYIKoZIzj0EAwMDaQAwZgIxAJqt+TiwMKfQv27brTaQE5lcTnBXqFyd
 B/FCNEAtNLBdmpPi3LpPtpLDDU+CnxGFgAIxAMEP+kvWM3KHiDt1+FiNp5zB0xdb
 OIM/BzzL4Jbpf5oKPDGF8rGSh/vvEVHGkfGiGA==
 -----END CERTIFICATE-----
privatekey: |
 -----BEGIN PRIVATE KEY-----
 MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDDQb0x7KTu4s6YwgTbj
 +w6bNdzen7X7Bb6ymfwokYry7vzc5/caHZgsWu0qCUECzqehZANiAAR/xO0Sr6tG
 KD9tPWwDsjVfqYRQeTRjveOeCZjyu0PjUhM/xGaabr3DJyvCrDfaJCseh+KzC3bs
 Js4CtsiuNlLurAOcipNtHUSdy18kE31GU/lsafBxz+Ri6hjL5LwR/Ow=
 -----END PRIVATE KEY-----
```

## Verify the agent credentials

***Fresh installation without any configuration***

```
mondoo status
 → mondoo cloud: https://api.mondoo.app
 ✘ agent is not registered
```

***Correct configuration with verified connectivity***

```
mondoo status
 → mondoo cloud: https://api.mondoo.app
 → space: //captain.api.mondoo.app/spaces/gallant-kilby-587371
 → agent is registered
 ✔ agent //agents.api.mondoo.app/spaces/gallant-kilby-587371/agents/1N9EGTzvlizF1n7vPtz21y7XFA3 authenticated successfully
```

***Invalid Credentials***

```
mondoo status
 → mondoo cloud: https://api.mondoo.app
 → space: //captain.api.mondoo.app/spaces/gallant-kilby-587371
 → agent is registered
 ✘ could not connect to mondoo cloud: rpc error: code = Unauthenticated desc = request permission unauthenticated
```
