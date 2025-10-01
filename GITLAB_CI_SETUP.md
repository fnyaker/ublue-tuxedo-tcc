# Configuration GitLab CI/CD

Ce document explique la configuration GitLab CI/CD pour ce projet, qui a été adapté depuis GitHub Actions.

## 📋 Vue d'ensemble

Le pipeline GitLab CI/CD construit automatiquement les images de conteneurs pour différentes variantes d'Aurora et Bluefin avec ou sans drivers Tuxedo.

## 🔧 Variables d'environnement

Les variables suivantes sont définies dans le pipeline :

- `IMAGE_DESC` : Description des images
- `IMAGE_REGISTRY` : Registry GitLab (`$CI_REGISTRY/$CI_PROJECT_NAMESPACE`)
- `ARTIFACTHUB_LOGO_URL` : URL du logo pour ArtifactHub

### Variables secrètes (à configurer dans GitLab)

Pour configurer les variables secrètes dans GitLab :
1. Allez dans **Settings** > **CI/CD** > **Variables**
2. Ajoutez les variables suivantes :

#### Optionnel : Signature des images avec Cosign

- `COSIGN_PRIVATE_KEY` : Clé privée pour signer les images avec Cosign (optionnel)
  - Type : **File** ou **Variable**
  - Protected : ✅ (recommandé)
  - Masked : ✅ (recommandé)

## 🚀 Déclenchement du pipeline

Le pipeline se déclenche automatiquement dans les cas suivants :

- **Push** sur les branches `main` ou `blackaurora`
- **Merge Request** (MR) - construit les images mais ne les pousse pas
- **Pipeline programmé** (schedule) - configurable dans GitLab
- **Déclenchement manuel** via l'interface GitLab

### Configuration d'un pipeline programmé

Pour reproduire le comportement GitHub (cron: `05 10 * * 1,4` - lundi et jeudi à 10h05) :

1. Allez dans **CI/CD** > **Schedules**
2. Cliquez sur **New schedule**
3. Configurez :
   - Description : "Weekly image rebuild"
   - Interval Pattern : Custom (`5 10 * * 1,4`)
   - Target Branch : `main`
   - Variables : (aucune nécessaire)

## 🏗️ Structure du pipeline

Le pipeline est composé d'un seul stage `build` avec plusieurs jobs parallèles :

### Images Aurora
- `build-aurora-blackdx` → `tuxedo-aurora-black`
- `build-aurora-dx` → `tuxedo-aurora-dx`
- `build-aurora-nodrivers` → `aurora-custom`

### Images Bluefin
- `build-bluefin-blackdx` → `tuxedo-bluefin-black`
- `build-bluefin-dx` → `tuxedo-bluefin-dx`
- `build-bluefin-nodrivers` → `bluefin-custom`

## 📦 Registry et tags

Les images sont poussées vers le **GitLab Container Registry** du projet :

```
registry.gitlab.com/VOTRE_NAMESPACE/VOTRE_PROJECT/IMAGE_NAME
```

### Alternatives au GitLab Container Registry

Vous pouvez pousser vos images vers d'autres registries en modifiant la variable `IMAGE_REGISTRY` et en ajoutant les credentials appropriés :

#### 1. **Docker Hub**
```yaml
variables:
  IMAGE_REGISTRY: "docker.io/VOTRE_USERNAME"
```
Ajoutez dans GitLab CI/CD Variables :
- `DOCKERHUB_USERNAME` : votre nom d'utilisateur Docker Hub
- `DOCKERHUB_TOKEN` : votre token d'accès ([créer un token](https://hub.docker.com/settings/security))

Modifiez le `before_script` dans `.gitlab-ci.yml` :
```yaml
before_script:
  - echo "$DOCKERHUB_TOKEN" | buildah login -u "$DOCKERHUB_USERNAME" --password-stdin docker.io
```

#### 2. **Quay.io (Red Hat)**
```yaml
variables:
  IMAGE_REGISTRY: "quay.io/VOTRE_USERNAME"
```
Ajoutez dans GitLab CI/CD Variables :
- `QUAY_USERNAME` : votre nom d'utilisateur Quay.io
- `QUAY_TOKEN` : votre token ou mot de passe

Modifiez le `before_script` :
```yaml
before_script:
  - echo "$QUAY_TOKEN" | buildah login -u "$QUAY_USERNAME" --password-stdin quay.io
```

#### 3. **GitHub Container Registry (ghcr.io)**
```yaml
variables:
  IMAGE_REGISTRY: "ghcr.io/VOTRE_USERNAME"
```
Ajoutez dans GitLab CI/CD Variables :
- `GITHUB_USERNAME` : votre nom d'utilisateur GitHub
- `GITHUB_TOKEN` : un Personal Access Token avec le scope `write:packages` ([créer un token](https://github.com/settings/tokens))

Modifiez le `before_script` :
```yaml
before_script:
  - echo "$GITHUB_TOKEN" | buildah login -u "$GITHUB_USERNAME" --password-stdin ghcr.io
```

#### 4. **Azure Container Registry (ACR)**
```yaml
variables:
  IMAGE_REGISTRY: "VOTRE_REGISTRY.azurecr.io"
```
Ajoutez dans GitLab CI/CD Variables :
- `ACR_USERNAME` : nom du service principal
- `ACR_PASSWORD` : mot de passe du service principal

#### 5. **Amazon ECR**
```yaml
variables:
  IMAGE_REGISTRY: "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com"
```
Nécessite AWS CLI et credentials configurés.

#### 6. **Pousser vers plusieurs registries**

Vous pouvez modifier le pipeline pour pousser vers plusieurs registries simultanément :

```yaml
.build-image-template:
  script:
    - |
      # ... (build existant) ...
      
      # Push vers GitLab
      buildah push "${IMAGE_FULL_LOWER}:${tag}"
      
      # Push vers Docker Hub
      DOCKERHUB_IMAGE="docker.io/VOTRE_USERNAME/${IMAGE_NAME}:${tag}"
      buildah tag "${IMAGE_FULL_LOWER}:build" "$DOCKERHUB_IMAGE"
      echo "$DOCKERHUB_TOKEN" | buildah login -u "$DOCKERHUB_USERNAME" --password-stdin docker.io
      buildah push "$DOCKERHUB_IMAGE"
      
      # Push vers Quay.io
      QUAY_IMAGE="quay.io/VOTRE_USERNAME/${IMAGE_NAME}:${tag}"
      buildah tag "${IMAGE_FULL_LOWER}:build" "$QUAY_IMAGE"
      echo "$QUAY_TOKEN" | buildah login -u "$QUAY_USERNAME" --password-stdin quay.io
      buildah push "$QUAY_IMAGE"
```

### Avantages par registry

| Registry | Avantages | Inconvénients |
|----------|-----------|---------------|
| **GitLab Container Registry** | Intégré, gratuit, credentials auto | Limité à GitLab |
| **Docker Hub** | Très populaire, facile d'accès | Limites de pull sur plan gratuit |
| **Quay.io** | Scan de sécurité gratuit, bon pour OSS | Interface moins intuitive |
| **ghcr.io** | Gratuit, illimité pour public | Nécessite compte GitHub |
| **Azure ACR** | Intégration Azure, géo-réplication | Payant |
| **Amazon ECR** | Intégration AWS, scalable | Payant, configuration complexe |

### Tags générés

Pour les branches `main` et `blackaurora` :
- `latest`
- `latest.YYYYMMDD` (ex: `latest.20251001`)
- `YYYYMMDD` (ex: `20251001`)

Pour les Merge Requests (preview uniquement, non poussé) :
- `mr-{MR_NUMBER}` (ex: `mr-42`)
- `sha-{COMMIT_SHORT_SHA}` (ex: `sha-a1b2c3d`)

## 🔒 Signature des images

Si vous configurez la variable `COSIGN_PRIVATE_KEY`, les images seront automatiquement signées avec Cosign après le push.

### Installation de Cosign

```bash
# Sur Linux
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Sur macOS avec Homebrew
brew install cosign

# Vérifier l'installation
cosign version
```

### Générer une paire de clés Cosign

```bash
# Génération de la paire de clés (vous serez invité à entrer un mot de passe)
cosign generate-key-pair

# Cela créera deux fichiers :
# - cosign.key  (clé privée - À GARDER SECRÈTE)
# - cosign.pub  (clé publique - peut être partagée)
```

### Configuration dans GitLab

1. **Ajouter la clé privée** :
   ```bash
   # Afficher le contenu de la clé privée
   cat cosign.key
   ```
   
2. Dans GitLab, allez dans **Settings** > **CI/CD** > **Variables**
3. Cliquez sur **Add variable**
4. Configurez :
   - **Key** : `COSIGN_PRIVATE_KEY`
   - **Value** : Collez le contenu complet de `cosign.key`
   - **Type** : `File` (recommandé) ou `Variable`
   - **Environment scope** : `All`
   - **Protect variable** : ✅ (coché)
   - **Mask variable** : ✅ (coché)

5. **Commitez la clé publique** dans votre repo :
   ```bash
   # La clé publique peut être partagée
   cp cosign.pub /chemin/vers/votre/repo/
   git add cosign.pub
   git commit -m "Add cosign public key for image verification"
   git push
   ```

### Vérifier une image signée

Les utilisateurs peuvent vérifier vos images avec la clé publique :

```bash
# Télécharger votre clé publique
wget https://gitlab.com/VOTRE_NAMESPACE/VOTRE_PROJECT/-/raw/main/cosign.pub

# Vérifier une image
cosign verify --key cosign.pub registry.gitlab.com/VOTRE_NAMESPACE/VOTRE_PROJECT/IMAGE_NAME:TAG
```

## 🔄 Différences avec GitHub Actions

| Aspect | GitHub Actions | GitLab CI |
|--------|---------------|-----------|
| Fichier de config | `.github/workflows/build.yml` | `.gitlab-ci.yml` |
| Registry | `ghcr.io` | `registry.gitlab.com` |
| Variables d'auth | `GITHUB_TOKEN` | `CI_REGISTRY_PASSWORD` |
| Matrix builds | `strategy.matrix` | Jobs parallèles explicites |
| Dependabot | `.github/dependabot.yml` | Renovate (`renovate.json`) |
| Scheduled runs | Cron dans workflow | Schedules dans CI/CD settings |

## 🛠️ Développement local

Pour tester localement la construction d'une image :

```bash
# Exemple pour aurora-dx
buildah bud \
  --format=oci \
  --file=Containerfiles/aurora/dx/Containerfile \
  --tag=tuxedo-aurora-dx:test \
  .
```

## 📝 Notes importantes

1. **Les MR ne poussent pas les images** : Sur les Merge Requests, les images sont construites pour validation mais ne sont pas poussées vers le registry.

2. **Container Registry** : Assurez-vous que le Container Registry est activé dans votre projet GitLab (**Settings** > **General** > **Visibility, project features, permissions** > **Container Registry**).

3. **Runners** : Le pipeline utilise l'image `quay.io/buildah/stable` et nécessite des runners avec support Docker/Podman.

4. **Renovate** : Pour activer Renovate sur GitLab, vous devez installer le Renovate Bot sur votre instance GitLab ou utiliser le service Mend Renovate (anciennement WhiteSource).

## 🐛 Dépannage

### Erreur "unauthorized: authentication required"

Vérifiez que les permissions du Container Registry sont correctement configurées. Par défaut, GitLab devrait fournir `CI_REGISTRY_USER` et `CI_REGISTRY_PASSWORD`.

### Les images ne sont pas poussées

Vérifiez que vous êtes bien sur une branche `main` ou `blackaurora`. Les MR ne poussent pas les images.

### Erreur avec Cosign

Si vous ne voulez pas signer les images, ne configurez simplement pas la variable `COSIGN_PRIVATE_KEY`. La signature est optionnelle.

## 📚 Ressources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [Buildah Documentation](https://buildah.io/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
