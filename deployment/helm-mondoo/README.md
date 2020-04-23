# Mondoo Helm Chart

## Prerequisites

- Kubernetes 1.12+
- Helm 3+

## Current Features

- Harbor Scanner API reachable under http://ingress/harbor/

## Installing the Chart

Upload the mondoo configuration as secret

```
kubectl create secret generic mondoo-agent-config --from-file=mondoo.yml=~/.mondoo.yml
```

Deploy the mondoo agent

```
$ helm install mondoo .
```

## Uninstalling the Chart

```
$ helm delete mondoo
```