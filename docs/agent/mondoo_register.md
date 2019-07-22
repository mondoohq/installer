## mondoo register

Registers Mondoo agent with Mondoo Cloud

### Synopsis


This command register the mondoo agent with Mondoo Cloud. It requires the 
'--token' argument.

You can generate a new registration token via the Mondoo Dashboard
https://mondoo.app -> Space -> Agents -> New. Copy the token and pass it in 
as the '--token' argument:
	

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
      --config string   config file (default is $HOME/.mondoo.yaml)
```

### SEE ALSO

* [mondoo](mondoo.md)	 - Mondoo CLI

