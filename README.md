# mon-app — demo CI/CD app

Petit dépôt de démonstration contenant :

- `Jenkinsfile` : pipeline Jenkins qui build, tag, push l'image Docker et déploie sur Kubernetes via `kubectl`.
- `deployment.yaml` / `service.yaml` : manifests Kubernetes sans Helm.
- Une petite app Node.js (`index.js`) et `Dockerfile`.

Prérequis
- Docker
- kubectl (configuré pour accéder à votre cluster)
- Jenkins (avec accès au daemon Docker ou un agent qui a Docker + kubectl)

Usage local
1. Installer les dépendances (pour le développement local) :

```powershell
npm install
node index.js
```

Construire et exécuter l'image Docker :

```powershell
docker build -t mon-app:local .
docker run -p 8080:80 mon-app:local
# puis ouvrir http://localhost:8080
```

Pousser vers Docker Hub (exemple) :

```powershell
# remplacer myuser/mon-app par votre repo
docker tag mon-app:local myuser/mon-app:1.0
docker login
docker push myuser/mon-app:1.0
```

Configurer Jenkins
1. Lancer Jenkins (ex: via Docker). Voir les notes dans les instructions fournies.
2. Ajouter Credentials:
   - `dockerhub-creds` (Username with password)
   - `kubeconfig` (Secret file) — upload de votre `~/.kube/config`
3. Créer un Pipeline Job et pointer sur ce repo (ou coller le `Jenkinsfile` dans le job).

Git & push vers GitHub
1. Initialiser le repo et pousser (exécuter depuis le dossier du projet):

```powershell
git init
git add .
git commit -m "Initial commit: mon-app + Jenkinsfile + manifests"
# Remplacez <remote-url> par l'URL de votre repo GitHub (ex: https://github.com/username/repo.git)
git remote add origin <remote-url>
git branch -M main
git push -u origin main
```

Notes
- Le `Jenkinsfile` suppose que Jenkins peut exécuter `docker` et `kubectl`. En production, préférez utiliser un agent dédié (node) qui a ces outils plutôt que d'exposer le socket Docker du conteneur Jenkins.
- Le pipeline remplace l'image dans `deployment.yaml` avant d'appliquer le manifest.
