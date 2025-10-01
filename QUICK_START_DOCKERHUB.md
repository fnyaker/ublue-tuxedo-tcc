# 🚀 Configuration rapide Docker Hub

## Option 1 : Script automatique (recommandé)

Exécutez simplement le script de configuration :

```bash
./setup-dockerhub.sh
```

Le script va :
1. ✅ Vous demander votre nom d'utilisateur Docker Hub
2. ✅ Mettre à jour automatiquement `.gitlab-ci.yml`
3. ✅ Vous donner les instructions pour configurer GitLab

## Option 2 : Configuration manuelle

### 1️⃣ Modifier `.gitlab-ci.yml`

Remplacez `VOTRE_USERNAME` par votre nom d'utilisateur Docker Hub dans la ligne 6 :

```yaml
IMAGE_REGISTRY: "docker.io/votre-nom-utilisateur"
```

### 2️⃣ Créer un token Docker Hub

1. Allez sur https://hub.docker.com/settings/security
2. Cliquez sur **New Access Token**
3. Copiez le token généré

### 3️⃣ Configurer les variables GitLab

Dans **Settings → CI/CD → Variables**, ajoutez :

| Key | Value | Protect | Mask |
|-----|-------|---------|------|
| `DOCKERHUB_USERNAME` | votre nom d'utilisateur | ✅ | ✅ |
| `DOCKERHUB_TOKEN` | votre token | ✅ | ✅ |

### 4️⃣ Pusher et tester

```bash
git add .gitlab-ci.yml
git commit -m "Configure Docker Hub"
git push origin main
```

## 📚 Documentation complète

- **Configuration détaillée** : [DOCKER_HUB_SETUP.md](./DOCKER_HUB_SETUP.md)
- **Configuration générale GitLab** : [GITLAB_CI_SETUP.md](./GITLAB_CI_SETUP.md)

## 📦 Images qui seront créées

Après le premier build réussi, vos images seront disponibles sur :

- `docker.io/VOTRE_USERNAME/tuxedo-aurora-black:latest`
- `docker.io/VOTRE_USERNAME/tuxedo-aurora-dx:latest`
- `docker.io/VOTRE_USERNAME/aurora-custom:latest`
- `docker.io/VOTRE_USERNAME/tuxedo-bluefin-black:latest`
- `docker.io/VOTRE_USERNAME/tuxedo-bluefin-dx:latest`
- `docker.io/VOTRE_USERNAME/bluefin-custom:latest`

## ⚡ Commandes rapides

```bash
# Tester une image
docker pull VOTRE_USERNAME/tuxedo-aurora-dx:latest

# Voir les logs du pipeline
# Allez sur: https://gitlab.com/VOTRE_NAMESPACE/VOTRE_PROJECT/-/pipelines

# Restaurer la configuration GitLab Container Registry
git checkout .gitlab-ci.yml
```

## 🆘 Besoin d'aide ?

- ❌ **Erreur d'authentification** → Vérifiez vos variables GitLab
- ❌ **Repository denied** → Créez le repository sur Docker Hub
- ❌ **Rate limit** → Attendez 6h ou upgrader votre compte
- 📖 **Autres problèmes** → Voir [DOCKER_HUB_SETUP.md](./DOCKER_HUB_SETUP.md)
