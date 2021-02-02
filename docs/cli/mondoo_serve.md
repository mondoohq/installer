## mondoo serve

Start a Mondoo in background serve mode

```
mondoo serve [flags]
```

### Options

```
  -b, --bind string   bind the server to an address (unix://file.sock, http://0.0.0.0:8989)
  -h, --help          help for serve
  -p, --port int      the port to listen on (default 8989)
  -t, --timer int     scan interval in minutes (default 60)
```

### Options inherited from parent commands

```
      --config string     config file (default is $HOME/.mondoo.yaml)
      --loglevel string   set log-level: error, warn, info, debug, trace (default "info")
  -v, --verbose           verbose output
```

### SEE ALSO

* [mondoo](README.md)	 - Mondoo CLI

