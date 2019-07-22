# Configuration

Every Mondoo agent needs to be registered to authenticate and authorize any request to Mondoo API. This ensures that all vulnerability data is securely transmitted. The agent ships with a `mondoo register` command that eases the process to retrieve agent credentials securely.

## Registration

The registration process registers your server or virtual machine with Mondoo API, so that you can see the instance vulnerabilities in Mondoo's Dashboard. This ensures a secure and trusted communication. Data is encrypted via HTTPs and payload is signed to ensure its not been tampered with.

At first, you need to create a new registration token via [Mondoo Dashboard](https://mondoo.app/) -> Select Space -> Agents -> New Agent (➕Icon in action menu). Then run `mondoo register --token 'paste_token_here'`. If the registration process was successful, the cli prints the agent resource name.

```
mondoo register --token "eyJhbGci...6NSUwUn2DUzsppL696"

✔  agent //agents.api.mondoo.app/spaces/gallant-payne-155889/agents/1NmjgNKCoeD9SOz2UHNkT9IdcVc registered successfully
```

Via this process, the agent is retrieving all the configuration required automatically.

## Configuration options

| Name           | Description                        |
| -------------- | -----------------------------------|
| `api-endpoint`| The url of the Mondoo Cloud, `https://api.mondoo.app` is the default configuration
| `agentmrn`| Agent Mondoo Resource Name, identifies the agent
| `spacemrn`| Space Mondoo Resource Name, identifies the  space that the agent belongs to
| `privatekey`| Agent's private key used to sign requests send to Mondoo API
| `certificate`| Agent's public certificate
| `collector`| In collector mode, the agent does not report on cli (if used it is normally "http")


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
  →  mondoo cloud: https://api.mondoo.app
  ✘  agent is not registered
```

***Correct configuration with verified connectivity***

```
mondoo status
  →  mondoo cloud: https://api.mondoo.app
  →  space: //captain.api.mondoo.app/spaces/gallant-kilby-587371
  →  agent is registered
  ✔  agent //agents.api.mondoo.app/spaces/gallant-kilby-587371/agents/1N9EGTzvlizF1n7vPtz21y7XFA3 authenticated successfully
```

***Invalid Credentials***

```
mondoo status
  →  mondoo cloud: https://api.mondoo.app
  →  space: //captain.api.mondoo.app/spaces/gallant-kilby-587371
  →  agent is registered
  ✘  could not connect to mondoo cloud: rpc error: code = Unauthenticated desc = request permission unauthenticated
```

