# Kubernetes Integration

Mondoo makes it very easy to scan all your running pods.

![Mondoo Kubernetes scan from CLI](../static/videos/k8s-scan.gif)

> NOTE: To ensure the maximum security, we recommend to scan container images before they are deployed into production e.g. within a CI/CD run or within a container registry

## Preconditions

Install and setup [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). Make sure you can see your pods:

```
kubectl get pods
NAME                          READY   STATUS                 RESTARTS   AGE
centos-6b88594b-jm7bp         0/1     CreateContainerError   0          5d1h
hello-node-7676b5fb8d-xck5l   1/1     Running                0          5d1h
```

## Scan

Mondoo leverages the configuration from `kubectl`. No additional configuration is required. To scan all context, run:

```
$ mondoo scan -t k8s://
```

You can also filter by context and namespace:

```
$ mondoo scan -t k8s://context/c1
$ mondoo scan -t k8s://context/c1/namespace/n1
$ mondoo scan -t k8s://namespace/n1
```