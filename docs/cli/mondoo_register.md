## mondoo register

Registers Mondoo agent with Mondoo Cloud

### Synopsis


This command register the mondoo agent with Mondoo Cloud by using a registration
token. To pass in the token, use the '--token' flag.

You can generate a new registration token via the Mondoo Dashboard
https://mondoo.app -> Space -> Agents -> New. Copy the token and pass it in 
as the '--token' argument or use 'mondoo agents generate-token'

Every agent remains registered until you explicitly unregister it. You can
unregister an agent on the Mondoo dashboard, or by using 'mondoo unregister'
	

```
mondoo register [flags]
```

### Options

```
      --api-endpoint string   mondoo api url
  -h, --help                  help for register
  -t, --token string          agent registration token
```

### Options inherited from parent commands

```
      --config string     config file (default is $HOME/.mondoo.yaml)
      --loglevel string   set log-level: error, warn, info, debug, trace (default "info")
  -v, --verbose           verbose output
```

### SEE ALSO

* [mondoo](README.md)	 - Mondoo CLI

