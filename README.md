# 🚀 Tuxedo Drivers for Universal Blue

Until official support, this is the repo to go to if you want Tuxedo drivers on your Universal Blue operating systems (Aurora, Bluefin, Bazzite) for Tuxedo or other Clevo laptops.

It also includes motorcomm yt6801 drivers patched to compile on 6.15+ kernels (thanks to: https://github.com/h4rm00n/yt6801-linux-driver)

## 📦 Available Images

### Aurora Variants
- **tuxedo-aurora-dx** - Aurora DX with Tuxedo drivers
- **tuxedo-aurora-black** - Aurora Black DX with Tuxedo drivers  
- **aurora-custom** - Aurora without Tuxedo drivers

### Bluefin Variants
- **tuxedo-bluefin-dx** - Bluefin DX with Tuxedo drivers
- **tuxedo-bluefin-black** - Bluefin Black DX with Tuxedo drivers
- **bluefin-custom** - Bluefin without Tuxedo drivers

## 🔧 Installation

### Using rpm-ostree

For Aurora DX with Tuxedo drivers:
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/fnyaker/tuxedo-aurora-dx
```

For other variants, replace the image name accordingly.

## ⚠️ Secure Boot

Secure boot is not tested but due to motorcomm drivers, I don't think everything will work with it. Feel free to test and raise an issue - it could be interesting to get it working.

---

## 🔄 GitLab CI/CD Migration (NEW!)

This project has been migrated from GitHub Actions to GitLab CI/CD with Docker Hub support.

### 🚀 Quick Start for Maintainers

**Want to build and push to Docker Hub?** Just run:

```bash
./setup-dockerhub.sh
```

Then follow the instructions to configure GitLab variables.

### 📚 Documentation

- **[Quick Start Guide](QUICK_START_DOCKERHUB.md)** - Get started in 5 minutes
- **[Docker Hub Setup](DOCKER_HUB_SETUP.md)** - Detailed Docker Hub configuration
- **[GitLab CI Setup](GITLAB_CI_SETUP.md)** - Complete GitLab CI/CD guide
- **[Migration Summary](MIGRATION_SUMMARY.md)** - Overview of GitHub → GitLab changes

### 🛠️ Pipeline Features

- ✅ Automatic builds on push to `main` and `blackaurora`
- ✅ Preview builds on Merge Requests
- ✅ Parallel building of all 6 image variants
- ✅ Scheduled builds (configurable)
- ✅ Optional Cosign image signing
- ✅ Docker Hub and other registries support

### 🔑 Required Configuration

To enable automated builds on GitLab, configure these variables in **Settings → CI/CD → Variables**:

| Variable | Description |
|----------|-------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token ([create one](https://hub.docker.com/settings/security)) |
| `COSIGN_PRIVATE_KEY` | (Optional) For signing images |

**Don't forget** to update `IMAGE_REGISTRY` in `.gitlab-ci.yml` with your Docker Hub username!


