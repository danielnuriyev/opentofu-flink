output "kubeconfig" {
  description = "Path to the Kind cluster kubeconfig (from opentofu-kind)"
  value       = local.kubeconfig
}

output "webui_url" {
  description = "Flink Web UI URL (via port-forward)"
  value       = "http://localhost:8084"
}

output "rest_address" {
  description = "Flink REST API address (in-cluster)"
  value       = "http://flink-jobmanager.flink.svc.cluster.local:8081"
}

output "verify" {
  description = "Commands to verify Flink is running"
  value       = <<-EOT
    export KUBECONFIG=${local.kubeconfig}

    kubectl get pods -n flink
    kubectl port-forward -n flink svc/flink-jobmanager 8084:8081
    curl http://localhost:8084/overview
  EOT
}
