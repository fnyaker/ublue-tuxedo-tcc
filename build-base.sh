#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# ============================================================
# Base Build Script
# ============================================================
# This script installs base utilities and configurations
# common to all Tuxedo image variants.
# ============================================================

echo "Installing base utilities and configurations..."
df -h

# ============ Base Custom Utilities ===========
rpm-ostree install tmux
rpm-ostree install gnome-disk-utility

# Enable podman socket for container management
systemctl enable podman.socket

echo "Base utilities installation completed!"
