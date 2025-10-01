# 🐳 Configuration Docker Hub pour GitLab CI/CD

Ce guide vous explique comment configurer GitLab CI/CD pour pousser vos images vers Docker Hub.

## 📋 Prérequis

1. **Un compte Docker Hub** : [Créer un compte](https://hub.docker.com/signup)
2. **Un Access Token Docker Hub** (recommandé plutôt que le mot de passe)

## 🔑 Étape 1 : Créer un Access Token Docker Hub

1. Connectez-vous à [Docker Hub](https://hub.docker.com/)
2. Cliquez sur votre nom d'utilisateur en haut à droite → **Account Settings**
3. Allez dans **Security** → **Personal Access Tokens** ou [accès direct](https://hub.docker.com/settings/security)
4. Cliquez sur **New Access Token**
5. Configurez :
   - **Description** : `GitLab CI/CD` (ou autre nom descriptif)
   - **Access permissions** : `Read, Write, Delete` (ou `Read & Write` minimum)
6. Cliquez sur **Generate**
7. **COPIEZ LE TOKEN IMMÉDIATEMENT** (vous ne pourrez plus le voir après)

## 🛠️ Étape 2 : Configurer les variables dans GitLab

1. Allez dans votre projet GitLab
2. Naviguez vers **Settings** → **CI/CD**
3. Trouvez la section **Variables** et cliquez sur **Expand**
4. Ajoutez les deux variables suivantes :

### Variable 1 : DOCKERHUB_USERNAME

- Cliquez sur **Add variable**
- **Key** : `DOCKERHUB_USERNAME`
- **Value** : `votre-nom-utilisateur-dockerhub`
- **Type** : `Variable`
- **Environment scope** : `All`
- **Protect variable** : ☑️ (coché - recommandé)
- **Mask variable** : ☑️ (coché)
- **Expand variable reference** : ☐ (décoché)
- Cliquez sur **Add variable**

### Variable 2 : DOCKERHUB_TOKEN

- Cliquez sur **Add variable**
- **Key** : `DOCKERHUB_TOKEN`
- **Value** : `collez-votre-token-dockerhub`
- **Type** : `Variable`
- **Environment scope** : `All`
- **Protect variable** : ☑️ (coché - recommandé)
- **Mask variable** : ☑️ (coché)
- **Expand variable reference** : ☐ (décoché)
- Cliquez sur **Add variable**

## ✏️ Étape 3 : Modifier le fichier .gitlab-ci.yml

Ouvrez le fichier `.gitlab-ci.yml` et modifiez la variable `IMAGE_REGISTRY` :

```yaml
variables:
  IMAGE_DESC: "Brickman240 updated images with tuxedo drivers"
  # Remplacez VOTRE_USERNAME par votre nom d'utilisateur Docker Hub
  IMAGE_REGISTRY: "docker.io/VOTRE_USERNAME"
  ARTIFACTHUB_LOGO_URL: "https://avatars.githubusercontent.com/u/120078124?s=200&v=4"
```

**Exemple** : Si votre nom d'utilisateur Docker Hub est `johndoe`, remplacez par :
```yaml
  IMAGE_REGISTRY: "docker.io/johndoe"
```

Cette modification a déjà été faite automatiquement, mais vérifiez que `VOTRE_USERNAME` est bien remplacé par votre vrai nom d'utilisateur Docker Hub.

## 🚀 Étape 4 : Créer les repositories sur Docker Hub (optionnel)

Docker Hub créera automatiquement les repositories lors du premier push, mais vous pouvez les créer manuellement pour mieux les configurer :

1. Allez sur [Docker Hub](https://hub.docker.com/)
2. Cliquez sur **Repositories** → **Create Repository**
3. Créez les repositories suivants (un par un) :
   - `tuxedo-aurora-black`
   - `tuxedo-aurora-dx`
   - `aurora-custom`
   - `tuxedo-bluefin-black`
   - `tuxedo-bluefin-dx`
   - `bluefin-custom`
4. Pour chaque repository :
   - **Name** : le nom ci-dessus
   - **Description** : Description de votre image
   - **Visibility** : `Public` (recommandé) ou `Private`

## ✅ Étape 5 : Tester le pipeline

1. Commitez et pushez vos modifications :
   ```bash
   git add .gitlab-ci.yml
   git commit -m "Configure Docker Hub registry"
   git push origin main
   ```

2. Le pipeline GitLab CI/CD se déclenchera automatiquement
3. Surveillez l'exécution dans **CI/CD** → **Pipelines**
4. Une fois terminé, vérifiez sur [Docker Hub](https://hub.docker.com/) que vos images sont présentes

## 🔍 Vérifier vos images

Une fois le pipeline terminé, vos images seront disponibles à :

```
docker.io/VOTRE_USERNAME/tuxedo-aurora-black:latest
docker.io/VOTRE_USERNAME/tuxedo-aurora-dx:latest
docker.io/VOTRE_USERNAME/aurora-custom:latest
docker.io/VOTRE_USERNAME/tuxedo-bluefin-black:latest
docker.io/VOTRE_USERNAME/tuxedo-bluefin-dx:latest
docker.io/VOTRE_USERNAME/bluefin-custom:latest
```

Pour tester localement :

```bash
# Exemple avec tuxedo-aurora-dx
docker pull VOTRE_USERNAME/tuxedo-aurora-dx:latest

# ou avec podman
podman pull VOTRE_USERNAME/tuxedo-aurora-dx:latest
```

## 📊 Limites de Docker Hub (plan gratuit)

| Aspect | Limite |
|--------|--------|
| **Repositories publics** | Illimité |
| **Repositories privés** | 1 repository |
| **Storage** | Illimité |
| **Pull requests** | 200 pulls / 6 heures (anonyme), illimité (authentifié) |
| **Push requests** | Illimité |
| **Parallel builds** | 1 build simultané |

Si vous dépassez les limites, considérez :
- Docker Pro ($5/mois) : 5000 pulls/jour, 5 repos privés
- Docker Team ($9/mois par utilisateur) : illimité
- Ou utilisez une alternative gratuite (Quay.io, ghcr.io)

## 🐛 Dépannage

### Erreur "unauthorized: incorrect username or password"

**Causes possibles** :
1. Le token n'est pas valide
2. Le nom d'utilisateur est incorrect
3. Les variables GitLab ne sont pas configurées correctement

**Solution** :
- Vérifiez que `DOCKERHUB_USERNAME` correspond exactement à votre nom d'utilisateur Docker Hub
- Générez un nouveau token sur Docker Hub
- Vérifiez que les variables sont bien configurées dans GitLab

### Erreur "denied: requested access to the resource is denied"

**Cause** : Le repository n'existe pas ou vous n'avez pas les permissions

**Solution** :
- Créez le repository manuellement sur Docker Hub
- Vérifiez que le nom dans `IMAGE_REGISTRY` correspond à votre nom d'utilisateur

### Les images ne sont pas poussées

**Vérifiez** :
1. Que vous êtes sur la branche `main` ou `blackaurora`
2. Que le pipeline ne s'est pas arrêté à cause d'une erreur
3. Les logs du job dans GitLab CI/CD

### Rate limit dépassé

Si vous voyez "You have reached your pull rate limit", attendez 6 heures ou :
1. Connectez-vous à Docker Hub depuis votre runner
2. Passez à un plan payant Docker Hub
3. Utilisez un autre registry (Quay.io, ghcr.io)

## 🔐 Sécurité

**Bonnes pratiques** :
- ✅ Utilisez toujours un Access Token, jamais votre mot de passe
- ✅ Activez "Protect variable" et "Mask variable" dans GitLab
- ✅ Limitez les permissions du token au strict nécessaire
- ✅ Renouvelez régulièrement vos tokens
- ❌ Ne commitez JAMAIS vos credentials dans Git
- ❌ Ne partagez JAMAIS votre token

## 📚 Ressources

- [Documentation Docker Hub](https://docs.docker.com/docker-hub/)
- [Gérer les Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [Limites Docker Hub](https://docs.docker.com/docker-hub/download-rate-limit/)
