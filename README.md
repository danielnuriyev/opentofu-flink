# Flink on Kind (OpenTofu)

Deploys [Apache Flink](https://flink.apache.org/) as a session cluster onto the Kind cluster created by [opentofu-kind](https://github.com/danielnuriyev/opentofu-kind).

## What it does

- Creates a `flink` namespace on the Kind cluster
- Runs a Flink 2.3.0 session cluster (`apache/flink:2.3.0-java17`)
- Deploys one JobManager and one TaskManager
- Exposes the Flink REST/Web UI on port `8081` in-cluster (`localhost:8084` via port-forward)
- Exposes JobManager and TaskManager JVM/Flink JMX metrics to Prometheus via `jmx-exporter` sidecars and a `ServiceMonitor` (requires [opentofu-monitoring](../opentofu-monitoring))

## Prerequisites

- Kind cluster from [opentofu-kind](https://github.com/danielnuriyev/opentofu-kind) (`../opentofu-kind/.kubeconfig` must exist)
- [opentofu-monitoring](../opentofu-monitoring) — Prometheus Operator (ServiceMonitor CRD)

Deploy monitoring before Flink if you want Prometheus scraping on first apply.

## Deploy

```bash
tofu init
tofu apply
```

## Flink → Iceberg → Trino

Flink does not ship with the Kafka or Iceberg SQL connectors. Use [test/python/consume_flink.py](../test/python/consume_flink.py) to install the connector JARs and submit a SQL job that reads Debezium events from Kafka topic `test`, parses the MongoDB document fields, and writes to the Iceberg table `default.events` on MinIO (`s3://warehouse/`). Trino queries that table via the `iceberg` catalog.

Requires [opentofu-minio](../opentofu-minio) for object storage.

```bash
cd ../test/python
uv run consume-flink
```

## Verify

Check pods are running:

```bash
export KUBECONFIG=../opentofu-kind/.kubeconfig
kubectl get pods -n flink
```

Open the Flink Web UI:

```bash
kubectl port-forward -n flink svc/flink-jobmanager 8084:8081
curl http://localhost:8084/overview
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
