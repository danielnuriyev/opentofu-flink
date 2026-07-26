# Flink on Kind (OpenTofu)

Deploys [Apache Flink](https://flink.apache.org/) as a session cluster onto the Kind cluster created by [opentofu-kind](https://github.com/danielnuriyev/opentofu-kind).

## What it does

- Creates a `flink` namespace on the Kind cluster
- Runs a Flink 2.3.0 session cluster (`apache/flink:2.3.0-java17`)
- Deploys one JobManager and one TaskManager
- Exposes the Flink REST/Web UI on port `8081`

## Prerequisites

- Kind cluster from [opentofu-kind](https://github.com/danielnuriyev/opentofu-kind) (`../opentofu-kind/.kubeconfig` must exist)

## Deploy

```bash
tofu init
tofu apply
```

## Verify

Check pods are running:

```bash
export KUBECONFIG=../opentofu-kind/.kubeconfig
kubectl get pods -n flink
```

Open the Flink Web UI:

```bash
kubectl port-forward -n flink svc/flink-jobmanager 8081:8081
curl http://localhost:8081/overview
```

Expected output includes `"taskmanagers":1` and Flink version `2.3.0`.

## Cleanup

```bash
tofu destroy   # removes Flink from the cluster
```

The Kind cluster is managed separately in [opentofu-kind](https://github.com/danielnuriyev/opentofu-kind).

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Flink deployment via kubectl |
| `flink.yaml` | Flink session cluster Kubernetes manifest |
| `outputs.tf` | REST URL and verify commands |
