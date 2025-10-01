# 📂 Structure du projet

```
ublue-tuxedo-tcc/
│
├── 🔧 Configuration CI/CD
│   ├── .gitlab-ci.yml              # Pipeline GitLab CI/CD principal
│   ├── renovate.json               # Configuration Renovate (updates automatiques)
│   └── .github/                    # ⚠️ Anciens fichiers GitHub (à supprimer optionnellement)
│
├── 📚 Documentation
│   ├── README.md                   # Documentation principale du projet
│   ├── QUICK_START_DOCKERHUB.md    # 🚀 Démarrage rapide (5 min)
│   ├── DOCKER_HUB_SETUP.md         # 🐳 Guide détaillé Docker Hub
│   ├── GITLAB_CI_SETUP.md          # ⚙️ Guide complet GitLab CI/CD
│   ├── MIGRATION_SUMMARY.md        # 📋 Résumé de la migration GitHub→GitLab
│   ├── CHECKLIST.md                # ✅ Checklist de configuration
│   └── PROJECT_STRUCTURE.md        # 📂 Ce fichier
│
├── 🛠️ Scripts
│   ├── setup-dockerhub.sh          # Script de configuration automatique
│   ├── build-base.sh               # Script de build de base
│   ├── build_black.sh              # Script de build variante black
│   └── build_tuxedo.sh             # Script de build avec drivers Tuxedo
│
├── 🐳 Containerfiles
│   └── Containerfiles/
│       ├── aurora/
│       │   ├── dx/Containerfile           # Aurora DX
│       │   ├── blackdx/Containerfile      # Aurora Black DX
│       │   └── nodrivers/Containerfile    # Aurora sans drivers
│       └── bluefin/
│           ├── dx/Containerfile           # Bluefin DX
│           ├── blackdx/Containerfile      # Bluefin Black DX
│           └── nodrivers/Containerfile    # Bluefin sans drivers
│
├── 🔐 Sécurité
│   └── cosign.pub                  # Clé publique pour vérification des images
│
└── ⚙️ Configuration système
    ├── fixtuxedo                   # Script de fix Tuxedo
    ├── fixtuxedo.service           # Service systemd
    ├── tuxedo.repo                 # Repository Tuxedo
    ├── image.toml                  # Configuration image
    ├── iso.toml                    # Configuration ISO
    ├── artifacthub-repo.yml        # Configuration ArtifactHub
    ├── Justfile                    # Commandes Just
    └── LICENSE                     # Licence du projet
```

## 🎯 Workflow du pipeline GitLab CI/CD

```
┌─────────────────────────────────────────────────────────────┐
│                   DÉCLENCHEURS                              │
│  • Push sur main/blackaurora                                │
│  • Merge Request                                            │
│  • Pipeline programmé (schedule)                            │
│  • Déclenchement manuel                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    STAGE: BUILD                             │
│                                                             │
│  ┌───────────────────┐  ┌───────────────────┐             │
│  │ build-aurora-dx   │  │ build-aurora-black│             │
│  └───────────────────┘  └───────────────────┘             │
│                                                             │
│  ┌───────────────────┐  ┌───────────────────┐             │
│  │build-aurora-custom│  │build-bluefin-dx   │             │
│  └───────────────────┘  └───────────────────┘             │
│                                                             │
│  ┌───────────────────┐  ┌───────────────────┐             │
│  │build-bluefin-black│  │build-bluefin-custom             │
│  └───────────────────┘  └───────────────────┘             │
│                                                             │
│  Jobs exécutés en parallèle avec Buildah                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               PUSH VERS DOCKER HUB                          │
│  (uniquement sur main/blackaurora, pas sur MR)              │
│                                                             │
│  docker.io/VOTRE_USERNAME/                                  │
│    ├── tuxedo-aurora-dx:latest                             │
│    ├── tuxedo-aurora-black:latest                          │
│    ├── aurora-custom:latest                                │
│    ├── tuxedo-bluefin-dx:latest                            │
│    ├── tuxedo-bluefin-black:latest                         │
│    └── bluefin-custom:latest                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│          SIGNATURE COSIGN (optionnel)                       │
│  Si COSIGN_PRIVATE_KEY est configuré                        │
└─────────────────────────────────────────────────────────────┘
```

## 🗺️ Guides - Quel fichier lire en premier ?

```
Vous êtes...                           Lisez...
═══════════════════════════════════════════════════════════════

🆕 Nouveau ? Besoin de setup rapide    → QUICK_START_DOCKERHUB.md
                                        → CHECKLIST.md

🐳 Configuration Docker Hub             → DOCKER_HUB_SETUP.md

⚙️  Tout savoir sur GitLab CI          → GITLAB_CI_SETUP.md

📋 Vue d'ensemble de la migration       → MIGRATION_SUMMARY.md

🔍 Comprendre l'organisation            → PROJECT_STRUCTURE.md (ce fichier)

👨‍💻 Développeur/Mainteneur              → README.md
                                        → .gitlab-ci.yml
```

## 🔄 Flux de travail recommandé

### Pour les nouveaux utilisateurs

1. **Lire** `README.md` - Vue d'ensemble du projet
2. **Suivre** `QUICK_START_DOCKERHUB.md` - Setup en 5 minutes
3. **Utiliser** `setup-dockerhub.sh` - Configuration automatique
4. **Vérifier** avec `CHECKLIST.md` - S'assurer que tout est OK

### Pour une configuration détaillée

1. **Lire** `DOCKER_HUB_SETUP.md` - Tous les détails Docker Hub
2. **Consulter** `GITLAB_CI_SETUP.md` - Comprendre le pipeline
3. **Référencer** `MIGRATION_SUMMARY.md` - Différences GitHub vs GitLab

### Pour le développement

1. **Éditer** les `Containerfiles/*/Containerfile` selon vos besoins
2. **Tester** localement avec `buildah` ou `podman`
3. **Pousser** vers GitLab - le pipeline se déclenche automatiquement
4. **Vérifier** les logs dans GitLab CI/CD → Pipelines

## 📦 Images produites

Chaque variant produit 3 tags :

```
docker.io/VOTRE_USERNAME/IMAGE_NAME:
├── latest              # Dernière version stable
├── latest.20251001     # Date du build (format: YYYYMMDD)
└── 20251001            # Tag de date simple
```

### Images Aurora

| Nom du job | Image produite | Description |
|------------|----------------|-------------|
| `build-aurora-dx` | `tuxedo-aurora-dx` | Aurora DX + Tuxedo drivers |
| `build-aurora-blackdx` | `tuxedo-aurora-black` | Aurora Black DX + Tuxedo drivers |
| `build-aurora-nodrivers` | `aurora-custom` | Aurora personnalisé sans drivers |

### Images Bluefin

| Nom du job | Image produite | Description |
|------------|----------------|-------------|
| `build-bluefin-dx` | `tuxedo-bluefin-dx` | Bluefin DX + Tuxedo drivers |
| `build-bluefin-blackdx` | `tuxedo-bluefin-black` | Bluefin Black DX + Tuxedo drivers |
| `build-bluefin-nodrivers` | `bluefin-custom` | Bluefin personnalisé sans drivers |

## 🔧 Variables d'environnement utilisées

### Variables GitLab CI (automatiques)

| Variable | Description |
|----------|-------------|
| `CI_REGISTRY` | URL du registry GitLab |
| `CI_PROJECT_NAMESPACE` | Namespace du projet |
| `CI_PROJECT_PATH` | Chemin complet du projet |
| `CI_COMMIT_BRANCH` | Branche actuelle |
| `CI_COMMIT_SHA` | SHA du commit |
| `CI_PIPELINE_SOURCE` | Source du déclenchement |

### Variables à configurer (secrets)

| Variable | Requis | Description |
|----------|--------|-------------|
| `DOCKERHUB_USERNAME` | ✅ Oui | Nom d'utilisateur Docker Hub |
| `DOCKERHUB_TOKEN` | ✅ Oui | Token d'accès Docker Hub |
| `COSIGN_PRIVATE_KEY` | ⚠️ Optionnel | Clé privée pour signer les images |

### Variables du pipeline

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `IMAGE_DESC` | "Brickman240 updated images..." | Description des images |
| `IMAGE_REGISTRY` | `docker.io/VOTRE_USERNAME` | Registry cible |
| `ARTIFACTHUB_LOGO_URL` | URL du logo | Logo ArtifactHub |

## 🎨 Personnalisation

### Changer le registry

Dans `.gitlab-ci.yml`, modifiez :

```yaml
variables:
  IMAGE_REGISTRY: "nouveau-registry/namespace"
```

Puis adaptez le `before_script` pour l'authentification.

### Ajouter une nouvelle variante

1. Créez le Containerfile : `Containerfiles/nouvelle-variante/Containerfile`
2. Ajoutez un job dans `.gitlab-ci.yml` :

```yaml
build-nouvelle-variante:
  extends: .build-image-template
  variables:
    CONTAINERFILE: "Containerfiles/nouvelle-variante/Containerfile"
    IMAGE_NAME: "nom-de-limage"
```

### Modifier les tags

Dans `.gitlab-ci.yml`, section `script`, modifiez :

```bash
TAGS="latest latest.${CURRENT_DATE} ${CURRENT_DATE}"
```

## 📚 Ressources externes

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Buildah Documentation](https://buildah.io/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [Universal Blue](https://universal-blue.org/)

---

**💡 Astuce** : Utilisez `Ctrl+F` pour rechercher rapidement dans ce fichier !
