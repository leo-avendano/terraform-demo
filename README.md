## Infrastructure TDD Demo (Terraform + Terratest)

This repo demonstrates a progressive, test-driven workflow for infrastructure:

1. Red/Green TDD for a Docker-based nginx webserver using Terraform
2. Keep the webserver as a reusable Terraform module
3. Create a local Kubernetes cluster with Minikube
4. Move the same webserver module into Minikube and keep tests green

### Prerequisites

- Terraform >= 1.4
- Go (to run Terratest)
- Docker runtime (Docker Desktop or Colima)
- Minikube and kubectl (for steps 3–4)

If you use Colima, start it and set DOCKER_HOST:

```bash
colima start
export DOCKER_HOST=unix://$HOME/.colima/default/docker.sock
docker ps
```

### Step 1: Red/Green TDD – Terraform webserver (Docker)

Code paths:
- Module: `modules/nginx`
- Stack: `terraform/`
- Test: `infra_test.go` → `TestWebServerDocker`

Run the test (green):
```bash
go test -run TestWebServerDocker -v
```

Manually apply and open in a browser:
```bash
docker rm -f demo-nginx
terraform init
terraform apply -auto-approve
open http://localhost:8080
```

Tip: The Docker demo bind-mounts `site/` into the container, so editing `site/index.html` updates immediately without re-apply.

### Step 2: Modularize and keep tests passing

We already use a module (`modules/nginx`) from the stack (`terraform/`). Prove the refactor keeps behavior green:
```bash
go test -run TestWebServerDocker -v
```

### Step 3: Create Minikube cluster

```bash
minikube start -p minikube
kubectl config use-context minikube
kubectl get nodes
```

### Step 4: Deploy the webserver module into Minikube

Code paths:
- K8s Module: `modules/nginx-k8s` (uses ConfigMap for `index.html` and a NodePort service)
- K8s Stack: `terraform-k8s/`
- Test: `infra_test.go` → `TestWebServerK8s`

Run the Kubernetes test:
```bash
go test -run TestWebServerK8s -v
```

Or apply and browse manually:
```bash
terraform init
terraform apply -auto-approve
minikube service demo-nginx-svc --url -p minikube
kubectl -n default scale deploy/demo-nginx --replicas=5
# Copy the printed URL and open it, or:
curl "$(minikube service demo-nginx-svc --url -p minikube)"
```

Notes:
- K8s demo uses a ConfigMap created at apply time. To see content changes from `site/index.html`, re-apply the K8s stack.
- If the Docker provider cannot connect, ensure Docker is running and `DOCKER_HOST` is set (see Prerequisites).


