package test

import (
    "os"
    "os/exec"
    "path/filepath"
    "strings"
    "testing"
    "time"

    http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func ensureMinikube(t *testing.T) {
    t.Helper()
    if _, err := exec.LookPath("minikube"); err != nil {
        t.Skip("Skipping: minikube not installed")
    }
    // Start or ensure minikube is running
    cmd := exec.Command("minikube", "status", "-p", "minikube")
    out, _ := cmd.CombinedOutput()
    if !strings.Contains(string(out), "host: Running") {
        exec.Command("minikube", "start", "-p", "minikube").Run()
    }
}

func TestWebServerK8s(t *testing.T) {
    t.Parallel()
    ensureMinikube(t)

    terraformOptions := &terraform.Options{
        TerraformDir: "./terraform-k8s",
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Minikube exposes NodePort on cluster IP; we can use `minikube service` tunnel-less curl via node ip
    // For simplicity, use minikube service URL helper
    svcURLBytes, err := exec.Command("minikube", "service", "demo-nginx-svc", "--url", "-p", "minikube").CombinedOutput()
    if err != nil {
        t.Fatalf("failed to get service URL: %v, %s", err, string(svcURLBytes))
    }
    url := strings.TrimSpace(string(svcURLBytes))

    http_helper.HttpGetWithRetry(
        t,
        url,
        nil,
        200,
        "Hello from Nginx via Terraform",
        10,
        3*time.Second,
    )
}

func TestWebServerDocker(t *testing.T) {
    t.Parallel()

    // Detect Docker daemon socket and set DOCKER_HOST for the docker provider
    dockerHost := os.Getenv("DOCKER_HOST")
    if dockerHost == "" {
        // Try default socket
        if _, err := os.Stat("/var/run/docker.sock"); err == nil {
            dockerHost = "unix:///var/run/docker.sock"
        } else {
            // Try Colima and Docker Desktop socket locations
            homeDir, _ := os.UserHomeDir()
            colimaSock := filepath.Join(homeDir, ".colima", "default", "docker.sock")
            if _, err := os.Stat(colimaSock); err == nil {
                dockerHost = "unix://" + colimaSock
            } else {
                altSock := filepath.Join(homeDir, ".docker", "run", "docker.sock")
                if _, err := os.Stat(altSock); err == nil {
                    dockerHost = "unix://" + altSock
                }
            }
        }
    }
    if dockerHost == "" {
        t.Skip("Skipping: Docker daemon socket not found; ensure Docker is running")
    }

    terraformOptions := &terraform.Options{
        TerraformDir: "./terraform",
        EnvVars: map[string]string{
            "DOCKER_HOST": dockerHost,
        },
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    url := "http://localhost:8080"
    http_helper.HttpGetWithRetry(
        t,
        url,
        nil, // No custom TLS config
        200, // Expected status code
        "Hello from Nginx via Terraform", // Expected body substring
        5,   // Max retries
        10*time.Second, // Time between retries
    )
}