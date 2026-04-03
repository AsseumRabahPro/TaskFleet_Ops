# Changelog

Toutes les modifications notables de ce projet sont documentées ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet suit le [Semantic Versioning](https://semver.org/lang/fr/).

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
