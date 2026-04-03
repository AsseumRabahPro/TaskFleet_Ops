param(
    [ValidateSet("docker", "k8s")]
    [string]$Target = "docker",
    [string]$ImageName = "todo-backend:local"
)

$ErrorActionPreference = "Stop"

function Invoke-DockerFlow {
    Write-Host "[INFO] Demarrage Docker Compose..." -ForegroundColor Cyan
    docker compose up --build
}

function Invoke-KubernetesFlow {
    Write-Host "[INFO] Build de l'image backend: $ImageName" -ForegroundColor Cyan
    docker build -t $ImageName .

    Write-Host "[INFO] Application des manifests Kubernetes..." -ForegroundColor Cyan
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secret.yaml
    kubectl apply -f k8s/deployment-postgres.yaml
    kubectl apply -f k8s/service-postgres.yaml
    kubectl apply -f k8s/deployment-backend.yaml
    kubectl apply -f k8s/service-backend.yaml
    kubectl apply -f k8s/ingress.yaml
    kubectl apply -f k8s/hpa.yaml

    Write-Host "[INFO] Mise a jour de l'image du backend dans le Deployment..." -ForegroundColor Cyan
    kubectl set image deployment/todo-backend backend=$ImageName

    Write-Host "[INFO] Attente du rollout backend..." -ForegroundColor Cyan
    kubectl rollout status deployment/todo-backend

    Write-Host "[INFO] Services exposes:" -ForegroundColor Green
    kubectl get svc
}

if ($Target -eq "docker") {
    Invoke-DockerFlow
} else {
    Invoke-KubernetesFlow
}
