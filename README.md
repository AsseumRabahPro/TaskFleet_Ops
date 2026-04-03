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
3. [Structure du projet](#structure-du-projet)
4. [Backend Flask](#backend-flask)
5. [Docker Compose](#docker-compose)
6. [Kubernetes](#kubernetes)
7. [Scripts utilitaires](#scripts-utilitaires)
8. [Tests](#tests)
9. [Variables d'environnement](#variables-denvironnement)

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
│   ├── configmap.yaml     # Config non sensible (hôte DB, port, nom)
│   ├── secret.yaml        # Mot de passe DB (Kubernetes Secret)
│   ├── deployment-backend.yaml
│   ├── service-backend.yaml    # NodePort 30080
│   ├── deployment-postgres.yaml
│   └── service-postgres.yaml   # ClusterIP interne
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

Ou manuellement dans l'ordre :

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment-postgres.yaml
kubectl apply -f k8s/service-postgres.yaml
kubectl apply -f k8s/deployment-backend.yaml
kubectl apply -f k8s/service-backend.yaml
```

### 3. Architecture Kubernetes

```
┌───────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │  ConfigMap: todo-config                         │  │
│  │  Secret:    todo-secrets                        │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────┐       ┌──────────────────────┐  │
│  │ Deployment       │       │ Deployment           │  │
│  │ todo-backend     │──────▶│ todo-postgres        │  │
│  │ (1 replica)      │       │ (1 replica)          │  │
│  └──────────────────┘       └──────────────────────┘  │
│           │                           │                │
│  ┌──────────────────┐       ┌──────────────────────┐  │
│  │ Service          │       │ Service              │  │
│  │ NodePort :30080  │       │ ClusterIP :5432      │  │
│  └──────────────────┘       └──────────────────────┘  │
│           │                                            │
└───────────┼────────────────────────────────────────────┘
            │
      <node-ip>:30080
```

### 4. Accéder à l'API

```bash
# Minikube
curl http://$(minikube ip):30080/tasks

# Autre cluster
kubectl get nodes -o wide   # récupérer l'IP du node
curl http://<node-ip>:30080/tasks
```

### 5. Vérifier le déploiement

```bash
kubectl get pods
kubectl get svc
kubectl logs deployment/todo-backend
```

### 6. Supprimer le déploiement

```bash
kubectl delete -f k8s/
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
```
