# Scans

## Initiate the scan

### Cli

```bash
mondoo scan -t docker://7e87e2b3bf7a
```

### Automatic Scan

```yaml
cat scan.yaml
---
endpoint:
  url: docker://7e87e2b3bf7a
report:
  format: cli
```

```bash
cat scan.yaml | mondoo scan
```

## Supported Targets

- local system
- docker images
- docker stopped container
- docker running container
- ssh targets

### SSH

vag

- identity authentication

```
mondoo scan -t ssh://vagrant@192.168.100.70 -i /path/to/private_key
```

- agent authentication

```
ssh-add /path/to/private_key
mondoo scan -t ssh://vagrant@192.168.100.70
```

- password authentication

NOTE: this method is not recommended for production use, since it may expose your password in logs

```
mondoo scan -t ssh://vagrant:vagrant@192.168.100.70
```
