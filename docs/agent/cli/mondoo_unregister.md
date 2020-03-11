## mondoo unregister

Unregister Mondoo agent from Mondoo Cloud

### Synopsis


By calling mondoo unregister, the agent will be detached from Mondoo Cloud
This process also initiates a revokation of the agent certificates to ensure
the agent credentials cannot be used in future anymore.


```
mondoo unregister [flags]
```

### Options

```
      --force   force new registration
  -h, --help    help for unregister
```

### Options inherited from parent commands

```
      --config string   config file (default is $HOME/.mondoo.yaml)
```

### SEE ALSO

* [mondoo](mondoo.md)	 - Mondoo CLI

