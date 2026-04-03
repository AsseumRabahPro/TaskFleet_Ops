# Changelog

Toutes les modifications notables de ce projet sont documentées ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet suit le [Semantic Versioning](https://semver.org/lang/fr/).

---

## [1.1.0] — 2026-04-03

### Ajouté

#### Kubernetes — Scalabilité et haute disponibilité
- `deployment-backend.yaml` : passage à 3 replicas
- `deployment-backend.yaml` : `resources.requests` (cpu: 100m, memory: 128Mi) et `limits` (cpu: 250m, memory: 256Mi)
- `deployment-backend.yaml` : `readinessProbe` sur `GET /health` (initialDelay 10s, period 10s)
- `deployment-backend.yaml` : `livenessProbe` sur `GET /health` (initialDelay 20s, period 15s)
- `ingress.yaml` : Nginx Ingress compatible Minikube, hôte `todo-api.local`
- `hpa.yaml` : HorizontalPodAutoscaler v2, 2–5 replicas, seuil CPU 70%

#### Sécurité
- `DB_USER` migré du ConfigMap vers le Secret (tous les credentials groupés dans le même Secret)
- Commentaires explicatifs dans ConfigMap et Secret sur la séparation config/secrets

#### Documentation
- Section "Architecture" avec schéma ASCII complet (Ingress → HPA → Pods → PostgreSQL)
- Section "Pourquoi Kubernetes ?" (scalabilité, haute disponibilité, gestion config, auto-guérison)
- Section "Démonstration" (tests Docker, tests manuels curl, simulation de charge HPA)
- Tableau de toutes les ressources Kubernetes déployées
- Commandes : `kubectl apply -f k8s/`, `kubectl get pods`, `kubectl get services`, `kubectl get hpa`
- Table des matières mise à jour (12 sections)

---

## [1.0.0] — 2026-04-03

### Ajouté

#### Backend Flask
- API REST Todo avec 3 endpoints : `GET /tasks`, `POST /tasks`, `DELETE /tasks/<id>`
- Endpoint de santé `GET /health`
- Connexion PostgreSQL via SQLAlchemy + psycopg2-binary
- Validation de l'entrée utilisateur (titre vide → 400)
- Gestion des erreurs base de données (rollback + réponse 500)
- Retry automatique de connexion DB au démarrage (15 tentatives, 2s d'intervalle)
- Serveur Gunicorn en production

#### Docker
- `Dockerfile` Python 3.12-slim avec Gunicorn
- `docker-compose.yml` avec services `backend` et `postgres`
- Healthcheck PostgreSQL (`pg_isready`) avant démarrage du backend
- Volume persistant pour les données PostgreSQL

#### Kubernetes
- `configmap.yaml` : configuration non sensible (hôte, port, nom de la base)
- `secret.yaml` : mot de passe de la base de données
- `deployment-backend.yaml` : Deployment Flask avec injection ConfigMap + Secret
- `service-backend.yaml` : Service NodePort (port 30080)
- `deployment-postgres.yaml` : Deployment PostgreSQL avec volume emptyDir
- `service-postgres.yaml` : Service ClusterIP interne

#### Scripts
- `start.ps1` : démarrage Docker Compose ou Kubernetes en une commande
- `test-api.ps1` : suite de 7 tests fonctionnels automatisés

#### Documentation
- `README.md` complet avec schémas d'architecture, tableaux de référence
- `CONTRIBUTING.md` avec conventions et processus de contribution
- `CHANGELOG.md` (ce fichier)
- `.gitignore` adapté Python + Docker
