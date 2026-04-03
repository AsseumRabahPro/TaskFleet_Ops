# Guide de contribution

Merci de l'intérêt pour ce projet. Voici la marche à suivre pour contribuer.

---

## Environnement de développement

### Prérequis

- Python 3.12+
- Docker Desktop
- PowerShell 5.1+ (Windows) ou bash (Linux/macOS)

### Installation locale

```bash
# Créer un environnement virtuel
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/macOS

# Installer les dépendances
pip install -r requirements.txt
```

### Lancer la stack localement

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

### Lancer les tests

```powershell
powershell -ExecutionPolicy Bypass -File .\test-api.ps1
```

> Les tests nécessitent que la stack Docker soit démarrée et que l'API soit joignable sur `http://localhost:5000`.

---

## Conventions de code

### Python

- Style : [PEP 8](https://peps.python.org/pep-0008/)
- Longueur de ligne : 100 caractères maximum
- Nommage : `snake_case` pour les variables et fonctions, `PascalCase` pour les classes

### YAML (Kubernetes / Docker Compose)

- Indentation : 2 espaces
- Un fichier par ressource Kubernetes
- Les Secrets ne doivent jamais contenir de vraies valeurs sensibles dans git

### Git

- Commits en anglais, au format [Conventional Commits](https://www.conventionalcommits.org/) :

```
feat: add task priority field
fix: retry db connection on startup
docs: update kubernetes deployment steps
chore: bump Flask to 3.1.0
```

---

## Processus de contribution

1. Forker le dépôt
2. Créer une branche depuis `main` :
   ```bash
   git checkout -b feat/ma-fonctionnalite
   ```
3. Faire les modifications
4. Vérifier que les tests passent :
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\test-api.ps1
   ```
5. Committer avec un message clair
6. Ouvrir une Pull Request vers `main`

---

## Structure des branches

| Branche   | Usage                                         |
|-----------|-----------------------------------------------|
| `main`    | Code stable, prêt pour la production         |
| `feat/*`  | Nouvelles fonctionnalités                    |
| `fix/*`   | Corrections de bugs                          |
| `docs/*`  | Modifications de documentation uniquement    |
| `chore/*` | Maintenance (dépendances, CI, config)        |

---

## Signaler un problème

Ouvrir une issue en précisant :

- La version de Docker / kubectl utilisée
- Le système d'exploitation
- Les étapes exactes pour reproduire le problème
- Les logs pertinents (`docker compose logs` ou `kubectl logs`)
