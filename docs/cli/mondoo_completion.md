## mondoo completion

Generate completion script

### Synopsis

To load completions:

Bash:

$ source <(mondoo completion bash)

# To load completions for each session, execute once:
Linux:
  $ mondoo completion bash > /etc/bash_completion.d/mondoo
MacOS:
  $ mondoo completion bash > /usr/local/etc/bash_completion.d/mondoo

Zsh:

# If shell completion is not already enabled in your environment you will need
# to enable it.  You can execute the following once:

$ echo "autoload -U compinit; compinit" >> ~/.zshrc

# To load completions for each session, execute once:
$ mondoo completion zsh > "${fpath[1]}/_mondoo"

# You will need to start a new shell for this setup to take effect.

Fish:

$ mondoo completion fish | source

# To load completions for each session, execute once:
$ mondoo completion fish > ~/.config/fish/completions/mondoo.fish


```
mondoo completion [bash|zsh|fish|powershell]
```

### Options

```
  -h, --help   help for completion
```

### Options inherited from parent commands

```
      --config string     config file (default is $HOME/.mondoo.yaml)
      --loglevel string   set log-level: error, warn, info, debug, trace (default "info")
  -v, --verbose           verbose output
```

### SEE ALSO

* [mondoo](README.md)	 - Mondoo CLI

