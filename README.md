# Todo API — Flask · Docker · Kubernetes

Projet portfolio démontrant la conteneurisation et l'orchestration d'une API REST Python avec PostgreSQL.

[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)]()
[![Python](https://img.shields.io/badge/python-3.12-blue)]()
[![Docker](https://img.shields.io/badge/docker-compose-blue)]()
[![Kubernetes](https://img.shields.io/badge/kubernetes-manifests-blue)]()

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Architecture](#architecture)
4. [Structure du projet](#structure-du-projet)
5. [Backend Flask](#backend-flask)
6. [Docker Compose](#docker-compose)
7. [Kubernetes](#kubernetes)
8. [Pourquoi Kubernetes ?](#pourquoi-kubernetes-)
9. [Démonstration](#démonstration)
10. [CI/CD (GitHub Actions)](#cicd-github-actions)
11. [Scripts utilitaires](#scripts-utilitaires)
12. [Tests](#tests)
13. [Variables d'environnement](#variables-denvironnement)

---

## Vue d'ensemble

| Composant  | Technologie           | Version  |
|------------|-----------------------|----------|
| Backend    | Python / Flask        | 3.12 / 3.0.3 |
| ORM        | Flask-SQLAlchemy      | 3.1.1    |
| Driver DB  | psycopg2-binary       | 2.9.9    |
| Serveur    | Gunicorn              | 22.0.0   |
| Base de données | PostgreSQL       | 16-alpine |

---

## Prérequis

| Outil       | Docker Compose | Kubernetes (k8s) |
|-------------|----------------|------------------|
| Docker Desktop | ✅ requis    | ✅ requis         |
| kubectl     | ❌             | ✅ requis         |
| Cluster k8s | ❌             | ✅ requis (minikube, kind, etc.) |

---

## Architecture

```
                        ┌─────────────────────────────────────────────────────────┐
                        │                  Kubernetes Cluster                     │
                        │                                                         │
  Client HTTP           │  ┌──────────┐     ┌─────────────────────────────────┐  │
  ──────────────────────┼─▶│  Ingress │────▶│   Service: todo-backend-service │  │
  todo-api.local:80     │  │  (nginx) │     │   (NodePort :30080)             │  │
  ou <node-ip>:30080    │  └──────────┘     └────────────┬────────────────────┘  │
                        │                               │                         │
                        │              ┌────────────────▼──────────────┐          │
                        │              │  HPA: todo-backend-hpa        │          │
                        │              │  (2–5 replicas, seuil 70% CPU)│          │
                        │              └────────────────┬──────────────┘          │
                        │                               │                         │
                        │          ┌────────────────────▼────────────────────┐   │
                        │          │  Deployment: todo-backend (3 replicas)  │   │
                        │          │  ┌──────────┐┌──────────┐┌──────────┐  │   │
                        │          │  │  Pod 1   ││  Pod 2   ││  Pod 3   │  │   │
                        │          │  │ :5000    ││ :5000    ││ :5000    │  │   │
                        │          │  └────┬─────┘└────┬─────┘└────┬────┘  │   │
                        │          └───────┼────────────┼───────────┼───────┘   │
                        │                  └────────────▼───────────┘           │
                        │                  ┌────────────────────────┐           │
                        │                  │  Service: postgres      │           │
                        │                  │  (ClusterIP :5432)     │           │
                        │                  └────────────┬───────────┘           │
                        │                  ┌────────────▼───────────┐           │
                        │                  │  Deployment: postgres   │           │
                        │                  │  (1 replica)            │           │
                        │                  └────────────────────────┘           │
                        │                                                         │
                        │  ╔══════════════╗   ╔════════════════╗                 │
                        │  ║  ConfigMap   ║   ║     Secret     ║                 │
                        │  ║ DB_HOST      ║   ║ DB_USER        ║                 │
                        │  ║ DB_PORT      ║   ║ DB_PASSWORD    ║                 │
                        │  ║ DB_NAME      ║   ║ POSTGRES_PASS  ║                 │
                        │  ╚══════════════╝   ╚════════════════╝                 │
                        └─────────────────────────────────────────────────────────┘
```

---

## Structure du projet

```text
.
├── app/
│   ├── __init__.py        # Factory Flask + retry connexion DB
│   ├── config.py          # Configuration via variables d'environnement
│   ├── extensions.py      # Instance SQLAlchemy partagée
│   ├── models.py          # Modèle Task
│   └── routes.py          # Endpoints REST
├── k8s/
│   ├── configmap.yaml          # Config non sensible (hôte, port, nom DB)
│   ├── secret.yaml             # Credentials DB (user + password)
│   ├── deployment-backend.yaml # 3 replicas, probes, resources
│   ├── service-backend.yaml    # NodePort :30080
│   ├── deployment-postgres.yaml
│   ├── service-postgres.yaml   # ClusterIP interne
│   ├── ingress.yaml            # Nginx Ingress (todo-api.local)
│   └── hpa.yaml                # HorizontalPodAutoscaler (2–5 pods, CPU 70%)
├── .dockerignore
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── run.py
├── start.ps1              # Script de démarrage (Docker ou k8s)
└── test-api.ps1           # Suite de tests fonctionnels
```

---

## Backend Flask

### Endpoints

| Méthode | Chemin           | Description              | Code succès |
|---------|------------------|--------------------------|-------------|
| GET     | `/health`        | Vérification de santé    | 200         |
| GET     | `/tasks`         | Liste toutes les tâches  | 200         |
| POST    | `/tasks`         | Crée une tâche           | 201         |
| DELETE  | `/tasks/<id>`    | Supprime une tâche       | 200         |

### Exemples de requêtes

```bash
# Lister les tâches
curl http://localhost:5000/tasks

# Créer une tâche
curl -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Apprendre Kubernetes"}'

# Supprimer une tâche
curl -X DELETE http://localhost:5000/tasks/1
```

### Réponses d'erreur

| Code | Cas                          | Body                                          |
|------|------------------------------|-----------------------------------------------|
| 400  | Titre absent ou vide         | `{"error": "Le champ 'title' est obligatoire."}` |
| 404  | Tâche inexistante            | `{"error": "Tache introuvable."}`             |
| 500  | Erreur base de données       | `{"error": "Erreur base de donnees ..."}`     |

---

## Docker Compose

### Démarrage en une commande

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Ou directement :

```bash
docker compose up --build
```

API disponible sur : `http://localhost:5000`

### Architecture Docker Compose

```
┌─────────────────────────────────────────┐
│            Docker Network               │
│                                         │
│  ┌───────────────┐   ┌───────────────┐  │
│  │  todo-backend │──▶│ todo-postgres │  │
│  │  :5000        │   │  :5432        │  │
│  └───────────────┘   └───────────────┘  │
│         │                               │
└─────────┼───────────────────────────────┘
          │
     localhost:5000
```

> Le backend attend que PostgreSQL soit `healthy` avant de démarrer grâce au `healthcheck` + `depends_on: condition: service_healthy`.

### Arrêter la stack

```bash
docker compose down        # Conserve le volume postgres
docker compose down -v     # Supprime aussi le volume (reset DB)
```

---

## Kubernetes

### 1. Préparer l'image

```bash
# Construire l'image localement
docker build -t <votre-registry>/todo-backend:1.0.0 .

# Pousser vers un registry
docker push <votre-registry>/todo-backend:1.0.0
```

Mettre à jour le champ `image` dans `k8s/deployment-backend.yaml` :

```yaml
image: <votre-registry>/todo-backend:1.0.0
```

> Avec Minikube, utiliser `minikube image load todo-backend:local` pour éviter le push registry.

### 2. Déployer en une commande

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1 -Target k8s
```

Ou appliquer l'intégralité du dossier `k8s/` en une seule commande `kubectl` :

```bash
kubectl apply -f k8s/
```

Ou dans l'ordre explicite :

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment-postgres.yaml
kubectl apply -f k8s/service-postgres.yaml
kubectl apply -f k8s/deployment-backend.yaml
kubectl apply -f k8s/service-backend.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

### 3. Ressources Kubernetes déployées

| Ressource | Fichier | Détail |
|---|---|---|
| ConfigMap | `configmap.yaml` | DB_HOST, DB_PORT, DB_NAME |
| Secret | `secret.yaml` | DB_USER, DB_PASSWORD, POSTGRES_PASSWORD |
| Deployment backend | `deployment-backend.yaml` | 3 replicas, probes, CPU/mem limits |
| Service backend | `service-backend.yaml` | NodePort :30080 |
| Deployment postgres | `deployment-postgres.yaml` | 1 replica |
| Service postgres | `service-postgres.yaml` | ClusterIP :5432 |
| Ingress | `ingress.yaml` | Nginx, `todo-api.local` |
| HPA | `hpa.yaml` | 2–5 pods, seuil 70% CPU |

### 4. Accéder à l'API

```bash
# Via NodePort (sans Ingress)
curl http://$(minikube ip):30080/tasks

# Via Ingress (après activation nginx + ajout dans /etc/hosts)
# Linux/macOS : echo "$(minikube ip)  todo-api.local" >> /etc/hosts
# Windows     : ajouter "<minikube-ip>  todo-api.local" dans
#               C:\Windows\System32\drivers\etc\hosts
curl http://todo-api.local/tasks
```

### 5. Commandes de supervision

```bash
# Vue d'ensemble des pods (avec statut readiness)
kubectl get pods

# Vue d'ensemble des services
kubectl get services

# État du HPA (replicas courants vs cible)
kubectl get hpa

# Logs du backend
kubectl logs deployment/todo-backend

# Détails d'un pod (utile pour diagnostiquer les probes)
kubectl describe pod -l app=todo-backend
```

### 6. Supprimer le déploiement

```bash
kubectl delete -f k8s/
```

---

## Pourquoi Kubernetes ?

Kubernetes n'est pas seulement un outil de déploiement : c'est une plateforme d'orchestration qui répond à des problématiques réelles en environnement de production.

### Scalabilité

Dans une entreprise comme Naval Group, un pic de charge (fin de journée, déploiement massif) peut multiplier le trafic par 10 en quelques secondes. Kubernetes permet de répondre à cela de deux façons :

- **Horizontale (HPA)** : ajoute automatiquement des pods selon l'utilisation CPU/mémoire, sans interruption de service.
- **Manuelle instantanée** : `kubectl scale deployment/todo-backend --replicas=10` suffit pour absorber un pic.

### Haute disponibilité

Avec 3 replicas, si un pod crashe (OOM, exception non gérée), Kubernetes en redémarre un automatiquement pendant que les 2 autres continuent à servir le trafic. Les probes `readiness` et `liveness` garantissent qu'aucune requête n'est routée vers un pod non prêt.

### Gestion de la configuration

Le découplage `ConfigMap` / `Secret` / code applicatif permet de :

- Modifier la configuration sans reconstruire l'image Docker
- Appliquer des valeurs différentes selon l'environnement (dev / staging / prod) sans toucher au code
- Restreindre l'accès aux secrets via RBAC Kubernetes

### Auto-guérison

Si un nœud tombe en panne, Kubernetes reprogramme les pods sur un autre nœud disponible automatiquement, sans intervention humaine.

---

## Démonstration

Cette section décrit comment tester l'API en conditions réelles, que ce soit avec Docker Compose ou Kubernetes.

### 1. Démarrer la stack Docker (développement)

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

### 2. Lancer la suite de tests automatisés

```powershell
powershell -ExecutionPolicy Bypass -File .\test-api.ps1
```

Résultat attendu :

```
[INFO] Base URL: http://localhost:5000
[PASS] GET /health retourne 200 et status=ok
[PASS] GET /tasks retourne 200 et un tableau
[PASS] POST /tasks cree une tache
[PASS] GET /tasks contient la tache creee
[PASS] DELETE /tasks/<id> supprime la tache
[PASS] DELETE /tasks/999999 retourne 404
[PASS] POST /tasks avec titre vide retourne 400
[RESULT] Tous les tests sont passes
```

### 3. Tests manuels curl

```bash
# Créer plusieurs tâches
curl -s -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Déployer sur Kubernetes"}' | python -m json.tool

curl -s -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Configurer le CI/CD"}' | python -m json.tool

# Lister toutes les tâches
curl -s http://localhost:5000/tasks | python -m json.tool

# Supprimer la première tâche
curl -s -X DELETE http://localhost:5000/tasks/1

# Vérifier la suppression
curl -s http://localhost:5000/tasks | python -m json.tool
```

### 4. Tester le HPA sur Kubernetes (simulation de charge)

```bash
# Dans un premier terminal : générer de la charge
kubectl run load-generator --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://todo-backend-service:5000/tasks; done"

# Dans un second terminal : observer le HPA scaler
kubectl get hpa todo-backend-hpa --watch

# Arrêter la charge
kubectl delete pod load-generator
```

---

## CI/CD (GitHub Actions)

Le pipeline est défini dans `.github/workflows/ci-cd.yml` et comporte 3 jobs :

1. `ci` (push + pull_request)
  - Build Docker Compose
  - Attente de `GET /health`
  - Exécution de `test-api.ps1`
2. `publish` (push sur `main` + manual run)
  - Build de l'image backend
  - Push sur `ghcr.io/<owner>/taskfleet-ops-backend`
  - Tags : `latest` (branche par défaut) + `sha-<commit>`
3. `deploy` (manual run uniquement)
  - Applique `kubectl apply -f k8s/`
  - Met à jour l'image du Deployment backend avec le tag SHA
  - Vérifie le rollout et affiche pods/services/ingress/hpa

### Secrets GitHub requis

- `KUBE_CONFIG_BASE64` (optionnel, requis seulement pour le job `deploy`)
  - Contient le kubeconfig encodé en base64
  - Génération : `base64 -w 0 ~/.kube/config` (Linux) ou équivalent PowerShell

### Déclenchement

```bash
# CI sur PR/push: automatique

# Déclenchement manuel (avec déploiement)
# GitHub > Actions > CI-CD > Run workflow > cocher "deploy"
```

---

## Scripts utilitaires

### `start.ps1` — Démarrage

| Paramètre  | Valeur    | Description               |
|------------|-----------|---------------------------|
| `-Target`  | `docker`  | (défaut) Lance Docker Compose |
| `-Target`  | `k8s`     | Déploie sur Kubernetes    |
| `-ImageName` | `todo-backend:local` | Nom de l'image pour k8s |

```powershell
# Docker (défaut)
powershell -ExecutionPolicy Bypass -File .\start.ps1

# Kubernetes
powershell -ExecutionPolicy Bypass -File .\start.ps1 -Target k8s -ImageName monregistry/todo-backend:1.0.0
```

### `test-api.ps1` — Tests fonctionnels

```powershell
# Contre localhost:5000 (défaut)
powershell -ExecutionPolicy Bypass -File .\test-api.ps1

# Contre une URL personnalisée
powershell -ExecutionPolicy Bypass -File .\test-api.ps1 -BaseUrl http://<node-ip>:30080
```

---

## Tests

La suite `test-api.ps1` couvre 7 cas :

| # | Test                                   | Code attendu |
|---|----------------------------------------|--------------|
| 1 | GET /health                            | 200          |
| 2 | GET /tasks (liste vide ou existante)   | 200          |
| 3 | POST /tasks avec titre valide          | 201          |
| 4 | GET /tasks contient la tâche créée     | 200          |
| 5 | DELETE /tasks/<id> existant            | 200          |
| 6 | DELETE /tasks/999999 (inexistant)      | 404          |
| 7 | POST /tasks avec titre vide            | 400          |

---

## Variables d'environnement

| Variable      | Défaut      | Description              |
|---------------|-------------|--------------------------|
| `DB_HOST`     | `localhost` | Hôte PostgreSQL          |
| `DB_PORT`     | `5432`      | Port PostgreSQL          |
| `DB_USER`     | `postgres`  | Utilisateur PostgreSQL   |
| `DB_PASSWORD` | `postgres`  | Mot de passe PostgreSQL  |
| `DB_NAME`     | `todo_db`   | Nom de la base           |

> En production, ne jamais stocker les mots de passe en clair. Utiliser un gestionnaire de secrets (Kubernetes Secret + RBAC, HashiCorp Vault, etc.).
