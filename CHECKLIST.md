# ✅ Checklist de configuration GitLab + Docker Hub

Suivez cette checklist pour configurer votre pipeline GitLab CI/CD avec Docker Hub.

## 📋 Prérequis

- [ ] Compte Docker Hub créé ([s'inscrire](https://hub.docker.com/signup))
- [ ] Projet GitLab existant
- [ ] Accès aux paramètres CI/CD du projet GitLab

---

## 🔧 Configuration (15 minutes)

### Étape 1 : Docker Hub

- [ ] **Connexion à Docker Hub**
  - Allez sur https://hub.docker.com/
  - Connectez-vous avec votre compte

- [ ] **Créer un Access Token**
  - Allez sur https://hub.docker.com/settings/security
  - Cliquez sur "New Access Token"
  - Nom : `GitLab CI/CD`
  - Permissions : `Read, Write, Delete`
  - **Copiez le token immédiatement** (vous ne pourrez plus le voir après)
  - Sauvegardez-le temporairement dans un fichier sécurisé

### Étape 2 : Configuration locale

**Option A : Script automatique (recommandé)**

- [ ] **Exécuter le script de configuration**
  ```bash
  ./setup-dockerhub.sh
  ```
- [ ] Entrez votre nom d'utilisateur Docker Hub quand demandé
- [ ] Vérifiez que `.gitlab-ci.yml` a été mis à jour

**Option B : Configuration manuelle**

- [ ] **Éditer `.gitlab-ci.yml`**
  - Ligne 6 : Remplacez `VOTRE_USERNAME` par votre nom d'utilisateur Docker Hub
  - Avant : `IMAGE_REGISTRY: "docker.io/VOTRE_USERNAME"`
  - Après : `IMAGE_REGISTRY: "docker.io/votre-nom-utilisateur"`

### Étape 3 : Variables GitLab

- [ ] **Ouvrir les paramètres GitLab**
  - Allez sur votre projet GitLab
  - Menu : Settings → CI/CD
  - Section : Variables → Expand

- [ ] **Ajouter DOCKERHUB_USERNAME**
  - Cliquez sur "Add variable"
  - Key : `DOCKERHUB_USERNAME`
  - Value : `votre-nom-utilisateur-dockerhub`
  - Type : Variable
  - Protect variable : ☑️ (coché)
  - Mask variable : ☑️ (coché)
  - Save variable

- [ ] **Ajouter DOCKERHUB_TOKEN**
  - Cliquez sur "Add variable"
  - Key : `DOCKERHUB_TOKEN`
  - Value : `collez-votre-token-dockerhub` (de l'étape 1)
  - Type : Variable
  - Protect variable : ☑️ (coché)
  - Mask variable : ☑️ (coché)
  - Save variable

- [ ] **Vérifier les variables**
  - Vous devriez voir 2 variables masquées
  - Les valeurs doivent être cachées (••••••••)

### Étape 4 : Premier déploiement

- [ ] **Commiter et pousser**
  ```bash
  git add .gitlab-ci.yml
  git commit -m "Configure GitLab CI/CD with Docker Hub"
  git push origin main
  ```

- [ ] **Vérifier le pipeline**
  - Allez sur CI/CD → Pipelines dans GitLab
  - Le pipeline devrait démarrer automatiquement
  - 6 jobs de build devraient s'exécuter en parallèle

- [ ] **Attendre la fin du pipeline**
  - Durée estimée : 20-40 minutes (selon les runners)
  - Tous les jobs doivent être verts ✅

- [ ] **Vérifier sur Docker Hub**
  - Allez sur https://hub.docker.com/repositories/votre-username
  - Vous devriez voir 6 nouveaux repositories
  - Chaque repository devrait avoir 3 tags (latest, latest.YYYYMMDD, YYYYMMDD)

---

## 🎯 Configuration optionnelle

### Pipeline programmé (Schedule)

- [ ] **Configurer un pipeline automatique**
  - GitLab : CI/CD → Schedules → New schedule
  - Description : `Weekly image rebuild`
  - Interval Pattern : Custom → `5 10 * * 1,4` (Lundi et Jeudi à 10h05 UTC)
  - Target Branch : `main`
  - Variables : (laisser vide)
  - Save pipeline schedule

### Signature Cosign (Sécurité avancée)

- [ ] **Installer Cosign**
  ```bash
  # Linux
  wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
  chmod +x cosign-linux-amd64
  sudo mv cosign-linux-amd64 /usr/local/bin/cosign
  
  # macOS
  brew install cosign
  ```

- [ ] **Générer une paire de clés**
  ```bash
  cosign generate-key-pair
  # Entrez un mot de passe quand demandé
  # Cela crée cosign.key (privée) et cosign.pub (publique)
  ```

- [ ] **Ajouter la clé privée dans GitLab**
  - Settings → CI/CD → Variables → Add variable
  - Key : `COSIGN_PRIVATE_KEY`
  - Value : Contenu du fichier `cosign.key`
  - Type : File (recommandé)
  - Protect variable : ☑️
  - Mask variable : ☑️
  - Save variable

- [ ] **Commiter la clé publique**
  ```bash
  git add cosign.pub
  git commit -m "Add cosign public key"
  git push origin main
  ```

### Renovate (Mises à jour automatiques)

- [ ] **Activer Renovate sur GitLab**
  - Option 1 : Utiliser https://github.com/renovatebot/renovate
  - Option 2 : Self-hosted Renovate
  - Le fichier `renovate.json` est déjà configuré

---

## ✅ Vérification finale

- [ ] **Pipeline terminé avec succès**
  - Tous les jobs verts dans GitLab
  - Aucune erreur dans les logs

- [ ] **Images disponibles sur Docker Hub**
  - 6 repositories créés
  - Tags présents : latest, latest.YYYYMMDD, YYYYMMDD

- [ ] **Test de pull d'une image**
  ```bash
  docker pull votre-username/tuxedo-aurora-dx:latest
  # ou
  podman pull votre-username/tuxedo-aurora-dx:latest
  ```

- [ ] **Documentation à jour**
  - README.md mis à jour avec les nouvelles URLs Docker Hub

---

## 🐛 Dépannage

Si vous rencontrez des problèmes, consultez :

| Problème | Solution |
|----------|----------|
| ❌ Pipeline échoue à l'authentification | Vérifiez `DOCKERHUB_TOKEN` dans GitLab Variables |
| ❌ "VOTRE_USERNAME not found" | Modifiez `.gitlab-ci.yml` avec votre vrai username |
| ❌ "denied: access to resource" | Créez manuellement les repos sur Docker Hub |
| ❌ Rate limit Docker Hub | Attendez 6h ou upgradez votre compte |

**Documentation détaillée** : [DOCKER_HUB_SETUP.md](./DOCKER_HUB_SETUP.md)

---

## 📊 État de la configuration

**Date de configuration** : _____________

**Nom d'utilisateur Docker Hub** : _____________

**URL GitLab Project** : _____________

**État** :
- [ ] Configuration complète et fonctionnelle
- [ ] Premier build réussi
- [ ] Images disponibles sur Docker Hub
- [ ] Documentation mise à jour

---

## 📝 Notes personnelles

Ajoutez vos notes ici :

```
_______________________________________________________________

_______________________________________________________________

_______________________________________________________________
```

---

**Félicitations ! 🎉** Votre pipeline GitLab CI/CD est maintenant configuré !
