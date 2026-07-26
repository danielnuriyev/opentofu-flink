terraform {
  required_version = ">= 1.12.5"

  backend "local" {
    path = ".terraform.tfstate"
  }

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.0"
    }
  }
}

locals {
  kubeconfig = "${path.module}/../opentofu-kind/.kubeconfig"
}

resource "null_resource" "flink" {
  triggers = {
    manifest      = filemd5("${path.module}/flink.yaml")
    kubeconfig    = local.kubeconfig
    manifest_path = "${path.module}/flink.yaml"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      test -f "${local.kubeconfig}" || { echo "Kubeconfig not found. Run tofu apply in opentofu-kind first."; exit 1; }

      kubectl --kubeconfig="${local.kubeconfig}" wait --for=delete namespace/flink --timeout=120s 2>/dev/null || true
      kubectl --kubeconfig="${local.kubeconfig}" apply -f "${path.module}/flink.yaml"
      kubectl --kubeconfig="${local.kubeconfig}" wait --for=condition=ready pod -l component=jobmanager -n flink --timeout=300s
      kubectl --kubeconfig="${local.kubeconfig}" wait --for=condition=ready pod -l component=taskmanager -n flink --timeout=300s

      PF_PID=""
      trap 'if [ -n "$PF_PID" ]; then kill "$PF_PID" 2>/dev/null || true; fi' EXIT
      flink_ready=false
      for i in $(seq 1 30); do
        kubectl --kubeconfig="${local.kubeconfig}" port-forward -n flink svc/flink-jobmanager 8084:8081 >/tmp/flink-pf.log 2>&1 &
        PF_PID=$!
        for j in $(seq 1 10); do
          if curl -sf http://127.0.0.1:8084/overview >/dev/null; then
            echo "flink rest api ready"
            flink_ready=true
            break 2
          fi
          kill -0 "$PF_PID" 2>/dev/null || break
          sleep 1
        done
        kill "$PF_PID" 2>/dev/null || true
        wait "$PF_PID" 2>/dev/null || true
        PF_PID=""
        sleep 1
      done
      if [ "$flink_ready" != true ]; then
        echo "Flink REST API did not become ready"
        exit 1
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl --kubeconfig="${self.triggers.kubeconfig}" delete -f "${self.triggers.manifest_path}" --ignore-not-found --wait=false
    EOT
  }
}
